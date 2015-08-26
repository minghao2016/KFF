#ifndef _KERNEL_H_
#define _KERNEL_H_

#include "common.h"

namespace kff {
namespace translator {

struct AccessOffsets {
  int minx, maxx, miny, maxy, minz, maxz;
};

class TranslationContext;

class Kernel: public AstAttribute {
 public:
  typedef map<SgFunctionCallExp*, Kernel*> ChildMap;
 protected:
  SgFunctionDeclaration *decl_;
  GridSet rGrids_;
  SgInitializedNamePtrSet rGridVars_;
  GridSet wGrids_;
  SgInitializedNamePtrSet wGridVars_;
  Kernel *parent_;
  ChildMap calls_;
 public:
  Kernel(SgFunctionDeclaration *decl, TranslationContext *tx,
         Kernel *k = NULL);
  Kernel(const Kernel &k);
  virtual ~Kernel() {}
  const GridSet& GetInGrids() const;
  const GridSet& GetOutGrids() const;
  // Returns true if grid object g may be read in this
  // kernel.
#ifdef UNUSED_CODE    
  bool isRead(Grid *g) const;
  bool isReadAny(GridSet *gs) const;
#endif
  bool IsGridUnread(Grid *g) const;  
  bool IsGridParamRead(SgInitializedName *v) const;
  // Returns true if grid object g may be modified in this
  // kernel.
#ifdef UNUSED_CODE    
  bool isModified(Grid *g) const;
  bool isModifiedAny(GridSet *ngs) const;
#endif
  bool IsGridUnmodified(Grid *g) const;  
  bool IsGridParamModified(SgInitializedName *v) const;

  SgFunctionDeclaration *GetDecl() {
    return decl_;
  }

  SgInitializedNamePtrList &GetArgs() {
    return decl_->get_args();
  }

  SgFunctionDefinition *GetDef() {
    return decl_->get_definition();
  }
  void AppendChild(SgFunctionCallExp *call, Kernel *child);
  std::string GetName() const { return string(decl_->get_name()); }
  static const std::string name;
  Kernel *copy() {
    return new Kernel(*this);
  }
 protected:
  void AnalyzeGridWrites(TranslationContext &tx);
  void AnalyzeGridReads(TranslationContext &tx);  
};

class KernelBody: public AstAttribute {
 public:
  KernelBody() {}
  virtual ~KernelBody() {}
  static const std::string name;
  KernelBody *copy() {
    return new KernelBody();
  }
};

} // namespace translator
} // namespace kff

#endif
