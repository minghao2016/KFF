#ifndef _ATTRIBUTE_H_
#define _ATTRIBUTE_H_

#include "common.h"

namespace kff {
namespace translator {

class GridCallAttribute: public AstAttribute {
 public:
  enum KIND {GET, GET_PERIODIC, EMIT};  
  GridCallAttribute(SgInitializedName *grid_var,
                    KIND k);
  virtual ~GridCallAttribute();
  static const std::string name;
  AstAttribute *copy();
  SgInitializedName *grid_var() { return grid_var_; };
  //! Returns true if the node is get.  
  bool IsGet();
  //! Returns true if the node is get_periodic.
  bool IsGetPeriodic();  
  bool IsEmit();  
 protected:
  SgInitializedName *grid_var_;
  KIND kind_;
};

void CopyAllAttributes(SgNode *dst, SgNode *src);

} // namespace translator
} // namespace kff

#endif
