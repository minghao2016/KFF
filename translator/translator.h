#ifndef _TRANSLATOR_H_
#define _TRANSLATOR_H_

#include "common.h"
#include "config.h"


namespace kff {
namespace translator {

class TranslationContext;
class GridType;
class StencilMap;
class Run;
class Grid;
class BuilderInterface;

class Translator: public rose_util::RoseASTTraversal {
 public:
  Translator(const Configuration &config);
  virtual ~Translator() {}
  virtual void SetUp(SgProject *project, TranslationContext *context,
                     BuilderInterface *rt_builder);  
  //! Translate the AST given by the SetUp function.
  /*!
    Call SetUp before calling this. Translator instances can be reused
    by calling Finish and SetUp.
   */
  virtual void Translate() = 0;
  //! Clear fields set for the AST set by SetUp.
  /*!
    Call this before translating different ASTs.
   */
  virtual void Finish();  
  virtual void Optimize() {}  

 protected:
  const Configuration &config_;
  SgProject *project_;
  SgSourceFile *src_;
  SgGlobal *global_scope_;
  TranslationContext *tx_;
  SgType *ivec_type_;
  SgClassDeclaration *grid_decl_;
  SgTypedefType *grid_type_;
  SgType *grid_ptr_type_;
  SgTypedefType *dom_type_;
  SgType *dom_ptr_type_;

  string grid_type_name_;
  string target_specific_macro_;

  BuilderInterface *rt_builder_;
  bool is_fortran_;

  virtual void buildGridDecl();
  virtual BuilderInterface *builder() {
    return rt_builder_;
  }
  //! Proocess all user-defined point types
  virtual void ProcessUserDefinedPointType();
  //! Process a user-defined point type
  /*!
    This is a helper function used by ProcessUserDefinedPointType.
   */
  virtual void ProcessUserDefinedPointType(
      SgClassDeclaration *grid_decl, GridType *gt) {}
  virtual void Visit(SgFunctionCallExp *node);
  virtual void Visit(SgFunctionDeclaration *node);
  virtual void Visit(SgDotExp *node);
  virtual void Visit(SgPntrArrRefExp *node);
  
  virtual void TranslateKernelDeclaration(SgFunctionDeclaration *node) {}
  virtual void TranslateInit(SgFunctionCallExp *node) {}
  virtual void TranslateNew(SgFunctionCallExp *node,
                            GridType *gt) {}
  virtual void TranslateFree(SgFunctionCallExp *node,
                             GridType *gt) {}
  virtual void TranslateCopyin(SgFunctionCallExp *node,
                               GridType *gt) {}
  virtual void TranslateCopyout(SgFunctionCallExp *node,
                                GridType *gt) {}
  
  virtual void TranslateGet(SgFunctionCallExp *node,
                            SgInitializedName *gv,
                            bool isKernel, bool is_periodic) {}
  // Returns true if translation is done. If this function returns
  // false, TranslateGet is used.
  virtual bool TranslateGetHost(SgFunctionCallExp *node,
                                SgInitializedName *gv) {
    return false;
  }
  //! Returns true if translation is done.
  /*!
    If this function returns false, translateGet is used.
  */
  virtual bool TranslateGetKernel(SgFunctionCallExp *node,
                                  SgInitializedName *gv,
                                  bool is_periodic) {
    return false;
  }
  //! Translates GridGet for user-defined types
  virtual void TranslateGetForUserDefinedType(
      SgDotExp *node, SgPntrArrRefExp *array_top) {}
  virtual void TranslateEmit(SgFunctionCallExp *node,
                             GridEmitAttribute *attr) {}
  virtual void TranslateSet(SgFunctionCallExp *node,
                            SgInitializedName *gv) {}
  virtual void TranslateGridCall(SgFunctionCallExp *node,
                                 SgInitializedName *gv) {}
  virtual void TranslateMap(SgFunctionCallExp *node,
                            StencilMap *s) {}
  virtual void TranslateRun(SgFunctionCallExp *node,
                            Run *run) {}
  //! Handler for a call to reduce grids.
  /*!
    \param rd A Reduce object.
   */
  virtual void TranslateReduceGrid(Reduce *rd) {}
  //! Handler for a call to kernel reductions.
  /*!
    \param rd A Reduce object.
   */
  virtual void TranslateReduceKernel(Reduce *rd) {}
  
  void defineMacro(const string &name, const string &val="");

  SgClassDeclaration *getDomainDeclaration() {
    SgClassType *t = isSgClassType(dom_type_->get_base_type());
    SgClassDeclaration *d =
        isSgClassDeclaration(t->get_declaration());
    assert(d);
    return d;
  }

};

} // namespace translator
} // namespace kff

#endif
