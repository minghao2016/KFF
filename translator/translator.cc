#include "translator.h"
#include "attribute.h"

namespace si = SageInterface;
namespace sb = SageBuilder;

namespace kff {
namespace translator {

Translator::Translator(const Configuration &config):
    config_(config),
    project_(NULL),
    src_(NULL),
    global_scope_(NULL),
    tx_(NULL),
    ivec_type_(NULL),
    grid_decl_(NULL),
    grid_type_(NULL),
    grid_ptr_type_(NULL),
    dom_type_(NULL),
    dom_ptr_type_(NULL),
    grid_type_name_("__PSGrid"),
    rt_builder_(NULL) {
}

void Translator::SetUp(SgProject *project, TranslationContext *context,
                       BuilderInterface *rt_builder) {
  assert(project);
  project_ = project;
  src_ = isSgSourceFile((*project_)[0]);
  assert(src_);
  tx_ = context;
  is_fortran_ = ru::IsFortran(project);

  global_scope_ = src_->get_globalScope();
  PSAssert(global_scope_);
  sb::pushScopeStack(global_scope_);

  rt_builder_ = rt_builder;

  ivec_type_ = sb::buildArrayType(sb::buildIntType(),
                                  sb::buildIntVal(PS_MAX_DIM));
  buildGridDecl();

  dom_type_ = isSgTypedefType(
      si::lookupNamedTypeInParentScopes(PS_DOMAIN_INTERNAL_TYPE_NAME,
                                        global_scope_));
  
  if (!is_fortran_) {
    PSAssert(dom_type_);
    LOG_DEBUG() << "dom base type: "
                << dom_type_->get_base_type()->class_name()
                << "\n";
    dom_ptr_type_ = sb::buildPointerType(dom_type_);
  }

  if (ru::IsFortranLikeLanguage()) {
    BOOST_FOREACH (SgClassDeclaration *cd,
                   si::querySubTree<SgClassDeclaration>(global_scope_)) {
      LOG_DEBUG() << "Class decl: " << cd->get_name()
                  << " (" << cd->class_name() << ")\n";
    }
    BOOST_FOREACH (SgNamedType *nd,
                   si::querySubTree<SgNamedType>(global_scope_)) {
      LOG_DEBUG() << "Named type: " << nd->get_name()
                  << " (" << nd->class_name() << ")\n";
    }
    BOOST_FOREACH (SgFunctionDeclaration *cd,
                   si::querySubTree<SgFunctionDeclaration>(global_scope_)) {
      LOG_DEBUG() << "Function decl: " << cd->get_name()
                  << " (" << cd->class_name() << ")\n";
    }
  }
}

void Translator::Finish() {
  project_ = NULL;
  src_ = NULL;
  tx_ = NULL;
  global_scope_ = NULL;
  ivec_type_ = NULL;
  grid_decl_ = NULL;
  grid_type_ = NULL;
  grid_ptr_type_ = NULL;
  dom_type_ = NULL;
  dom_ptr_type_ = NULL;
}

void Translator::defineMacro(const string &name,
                             const string &val) {
  string macro("#define " + name + " " + val + "\n");
  LOG_DEBUG() << "Adding text: " + macro;
#if 0
  // This doesn't work when called multiple times.
  si::addTextForUnparser(src_->get_globalScope(),
                         macro,
                         AstUnparseAttribute::e_inside);
#else
  si::attachArbitraryText(src_->get_globalScope(), macro);
#endif
                          
}

void Translator::buildGridDecl() {
  LOG_DEBUG() << "grid type name: " << grid_type_name_ << "\n";
  grid_type_ = isSgTypedefType(
      si::lookupNamedTypeInParentScopes(grid_type_name_, global_scope_));
  // Grid type is NULL when the translator is used as a helper class
  // for other translators.
  if (!grid_type_) {
    return;
  }
  LOG_DEBUG() << "grid type found\n";  
  grid_ptr_type_ = sb::buildPointerType(grid_type_);
  SgClassType *anont = isSgClassType(grid_type_->get_base_type());
  if (anont) {
    grid_decl_ = isSgClassDeclaration(
        anont->get_declaration()->get_definingDeclaration());
  } else {
    grid_decl_ = NULL;
  }
}

void Translator::Visit(SgFunctionDeclaration *node) {      
  if (tx_->isKernel(node)) {
    LOG_DEBUG() << "translate kernel declaration\n";
    TranslateKernelDeclaration(node);
  }
}

void Translator::Visit(SgFunctionCallExp *node) {
  SgVarRefExp *gexp = NULL;
  
  if (tx_->isNewCall(node)) {
    LOG_DEBUG() << "call to grid new found\n";
    const string name = ru::getFuncName(node);
    GridType *gt = tx_->findGridTypeByNew(name);
    assert(gt);
    TranslateNew(node, gt);
    return;
  }

  GridEmitAttribute *emit_attr=
      ru::GetASTAttribute<GridEmitAttribute>(node);
  if (emit_attr) {
    LOG_DEBUG() << "Translating emit\n";
    TranslateEmit(node, emit_attr);
    setSkipChildren();
    return;
  }

  if (GridType::isGridTypeSpecificCall(node)) {
    SgInitializedName* gv = GridType::getGridVarUsedInFuncCall(node);
    assert(gv);
    string methodName = GridType::GetGridFuncName(node);
    if (methodName == GridType::get_name ||
        methodName == GridType::get_periodic_name) {
      LOG_DEBUG() << "translating " << methodName << "\n";
      bool is_periodic = methodName == "get_periodic";
      node->addNewAttribute(
          GridCallAttribute::name,
          new GridCallAttribute(
              gv,
              (is_periodic) ? GridCallAttribute::GET_PERIODIC :
              GridCallAttribute::GET));
      SgFunctionDeclaration *caller = getContainingFunction(node);
      if (tx_->isKernel(caller)) {
        LOG_DEBUG() << "Translating grid get appearing in kernel\n";
      } else {
        LOG_DEBUG() << "Translating grid get appearing in host\n";
        if (is_periodic) {
          LOG_ERROR() << "Get periodic in host not allowed.\n";
          PSAbort(1);
        }
      }
      // Call getkernel first if it's used in kernel; if true
      // returned, done. otherwise, try gethost if it's used in host;
      // the final fallback is Translateget.
      if (!((tx_->isKernel(caller) &&
             TranslateGetKernel(node, gv, is_periodic)) ||
            (!tx_->isKernel(caller) && TranslateGetHost(node, gv)))) {
        TranslateGet(node, gv, tx_->isKernel(caller), is_periodic);
      }
    } else if (methodName == GridType::emit_name) {
      LOG_ERROR() << "Emit should be handled above with EmitAttribute\n";
      PSAbort(1);
    } else if (methodName == GridType::set_name) {
      LOG_DEBUG() << "translating set\n";
      TranslateSet(node, gv);
    } else {
      throw Exception("Unsupported grid call");
    }
    setSkipChildren();
    return;
  }


  if (tx_->IsMap(node)) {
    LOG_DEBUG() << "Translating map\n";
    LOG_DEBUG() << node->unparseToString() << "\n";
    TranslateMap(node, tx_->findMap(node));
    setSkipChildren();
    return;
  }

  if (tx_->isRun(node)) {
    LOG_DEBUG() << "Translating run\n";
    LOG_DEBUG() << node->unparseToString() << "\n";
    TranslateRun(node, tx_->findRun(node));
    setSkipChildren();
    return;
  }

  if (tx_->IsInit(node)) {
    LOG_DEBUG() << "Translating Init\n";
    LOG_DEBUG() << node->unparseToString() << "\n";
    TranslateInit(node);
    setSkipChildren();    
    return;
  }

  Reduce *rd = rose_util::GetASTAttribute<Reduce>(node);
  if (rd) {
    LOG_DEBUG() << "Translating Reduce\n";
    LOG_DEBUG() << node->unparseToString() << "\n";
    if (rd->IsGrid()) TranslateReduceGrid(rd);
    else TranslateReduceKernel(rd);
    setSkipChildren();
    return;
  }

  if ((gexp = tx_->IsFree(node))) {
    LOG_DEBUG() << "Translating Free\n";
    GridType *gt = ru::GetASTAttribute<GridType>(gexp->get_type());
    PSAssert(gt);
    TranslateFree(node, gt);
    setSkipChildren();
  }

  if ((gexp = tx_->IsCopyin(node))) {
    LOG_DEBUG() << "Translating Copyin\n";
    GridType *gt = ru::GetASTAttribute<GridType>(gexp->get_type());
    PSAssert(gt);
    TranslateCopyin(node, gt);
    setSkipChildren();
  }

  if ((gexp = tx_->IsCopyout(node))) {
    LOG_DEBUG() << "Translating Copyout\n";
    GridType *gt = ru::GetASTAttribute<GridType>(gexp->get_type());
    PSAssert(gt);
    TranslateCopyout(node, gt);
    setSkipChildren();
  }

  return;
}

void Translator::Visit(SgDotExp *node) {
  // skip expressions like get().x[i] since those are handled as
  // array member accesses. See Visit(SgPntrArrRefExp*).
  if (isSgPntrArrRefExp(node->get_parent())) {
    return;
  }
  SgExpression *lhs = node->get_lhs_operand();
  GridGetAttribute *gga =
      rose_util::GetASTAttribute<GridGetAttribute>(lhs);
  if (gga == NULL) return;
  TranslateGetForUserDefinedType(node, NULL);
}

void Translator::Visit(SgPntrArrRefExp *node) {
  // node may be a multi-dimensional array. If so, node has nested
  // SgPntrArrRefExp.
  
  // Process only the top-level array access expression
  if (isSgPntrArrRefExp(node->get_parent())) return;  

  // Find the base expression for this multi-dimensional array
  SgExpression *lhs_base = NULL;
  SgPntrArrRefExp *par = node;
  while (true) {
    lhs_base = par->get_lhs_operand();
    if (isSgPntrArrRefExp(lhs_base)) {
      par = isSgPntrArrRefExp(lhs_base);
      continue;
    } else {
      break;
    }
  }
  if (isSgDotExp(lhs_base)) {
    SgDotExp *dot = isSgDotExp(lhs_base);
    SgExpression *dot_lhs = dot->get_lhs_operand();
    GridGetAttribute *gga =
        ru::GetASTAttribute<GridGetAttribute>(dot_lhs);
    if (gga == NULL) return;
    TranslateGetForUserDefinedType(dot, node);
    return;
  }
}

void Translator::ProcessUserDefinedPointType() {
  // Visit each of user-defined grid element types
  NodeQuerySynthesizedAttributeType struct_decls =
      NodeQuery::querySubTree(project_, NodeQuery::StructDeclarations);
  FOREACH(it, struct_decls.begin(), struct_decls.end()) {
    SgClassDeclaration *decl = isSgClassDeclaration(*it);
    GridType *gt = ru::GetASTAttribute<GridType>(decl);
    if (gt == NULL) continue;
    if (!gt->IsUserDefinedPointType()) continue;
    LOG_DEBUG() << "User-defined point type found.\n";
    ProcessUserDefinedPointType(decl, gt);
  }
}


} // namespace translator
} // namespace kff
