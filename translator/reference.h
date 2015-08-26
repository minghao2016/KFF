#ifndef _REFERENCE_H_
#define _REFERENCE_H_

#include "translator.h"
#include "common.h"


namespace kff {
namespace translator {


class ReferenceTranslator {
 private:
  // If this flag is on, the Translator replace grid_dim[xyz] to the constant
  // value of grid size when it's feasible.
  bool flag_constant_grid_size_optimization_;

 public:
  ReferenceTranslator(const Configuration &config);
  virtual ~ReferenceTranslator();
  virtual void Translate();
  virtual void Optimize();
  virtual void SetUp(SgProject *project, TranslationContext *context,
                     BuilderInterface *rt_builder);  
  virtual void Finish();  

  bool flag_constant_grid_size_optimization() const {
    return flag_constant_grid_size_optimization_;
  }
  void set_flag_constant_grid_size_optimization(bool flag) {
    flag_constant_grid_size_optimization_ = flag;
  }

 protected:
  bool validate_ast_;
  //! Fixes inconsistency in AST.
  virtual void FixAST();
  //! Validates AST consistency.
  /*!
    Aborts when validation fails. Checking can be disabled with toggle
    variable validate_ast_.
   */
  virtual void ValidateASTConsistency();
  //virtual ReferenceRuntimeBuilder *builder() {
  //return dynamic_cast<ReferenceRuntimeBuilder*>(rt_builder_);
  //}
  virtual void TranslateKernelDeclaration(SgFunctionDeclaration *node);
  virtual void TranslateNew(SgFunctionCallExp *node, GridType *gt);
  virtual SgExprListExp *BuildNewArg(GridType *gt, Grid *g,
                                     SgVariableDeclaration *dim_decl,
                                     SgVariableDeclaration *type_info_decl);
  virtual void appendNewArgExtra(SgExprListExp *args, Grid *g,
                                 SgVariableDeclaration *dim_decl);
  virtual void TranslateGet(SgFunctionCallExp *node,
                            SgInitializedName *gv,
                            bool is_kernel,
                            bool is_periodic);
  virtual void TranslateEmit(SgFunctionCallExp *node,
                             GridEmitAttribute *attr);
  virtual void RemoveEmitDummyExp(SgExpression *emit);
  virtual void TranslateSet(SgFunctionCallExp *node, SgInitializedName *gv);
  virtual void TranslateMap(SgFunctionCallExp *node, StencilMap *s);
  //virtual SgFunctionDeclaration *BuildRunKernel(StencilMap *s);
  virtual SgFunctionDeclaration *BuildRunInteriorKernel(StencilMap *s) {
    return NULL;
  }
  virtual SgFunctionDeclarationPtrVector BuildRunBoundaryKernel(
      StencilMap *s) {
    std::vector<SgFunctionDeclaration*> v;
    return v;
  }

  virtual void DefineMapSpecificTypesAndFunctions();
  virtual void InsertStencilSpecificType(StencilMap *s,
                                         SgClassDeclaration *type_decl);
  virtual void InsertStencilSpecificFunc(StencilMap *s,
                                         SgFunctionDeclaration *func);
  virtual void TranslateRun(SgFunctionCallExp *node, Run *run);

  /** generate dlopen and dlsym code
   * @param[in] run
   * @param[in] ref ... function reference  '__PSStencilRun_0(1, ...);'
   * @param[in] index ... VAR's expression
   * @param[in] scope
   * @return    statement of dlopen and dlsym
   */
  virtual SgStatement *GenerateDlopenDlsym(
      Run *run, SgFunctionRefExp *ref,
      SgExpression *index, SgScopeStatement *scope);
  /** generate trial code
   * @param[in] run
   * @param[in] ref ... function reference  '__PSStencilRun_0(1, ...);'
   * @return    function declaration
   */
  virtual SgFunctionDeclaration *GenerateTrial(
      Run *run, SgFunctionRefExp *ref);

  virtual void TranslateReduceGrid(Reduce *rd);
  virtual void TranslateReduceKernel(Reduce *rd);
  //! Build a real function for reducing a grid.
  /*!
    \param rd A reduction of grid.
    \return A function declaration for reducing the grid.
   */
  virtual SgFunctionDeclaration *BuildReduceGrid(Reduce *rd);

  virtual void optimizeConstantSizedGrids();
  string grid_create_name_;
#if 0  
  virtual void TraceStencilRun(Run *run, SgScopeStatement *loop,
                               SgScopeStatement *cur_scope);
#endif  
  virtual void FixGridType();
};

} // namespace translator
} // namespace kff

#endif
