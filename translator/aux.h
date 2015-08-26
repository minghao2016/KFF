#ifndef _AUX_H_
#define _AUX_H_

#include "common.h"

namespace kff {
namespace translator {
namespace cuda {

SgFunctionCallExp *BuildCUDADeviceSynchronize(void);
SgFunctionCallExp *BuildCUDAStreamSynchronize(SgExpression *strm);
SgFunctionCallExp *BuildCUDADim3(SgExpression *x, SgExpression *y=NULL,
                                 SgExpression *z=NULL);
SgFunctionCallExp *BuildCUDADim3(int x);
SgFunctionCallExp *BuildCUDADim3(int x, int y);
SgFunctionCallExp *BuildCUDADim3(int x, int y, int z);

SgType *BuildCudaErrorType();
SgFunctionCallExp *BuildCUDAMalloc(SgExpression *buf, SgExpression *size);
SgFunctionCallExp *BuildCUDAFree(SgExpression *p);
SgFunctionCallExp *BuildCUDAMallocHost(SgExpression *buf, SgExpression *size);
SgFunctionCallExp *BuildCUDAFreeHost(SgExpression *p);

enum CudaFuncCache {
  cudaFuncCachePreferNone,
  cudaFuncCachePreferShared,
  cudaFuncCachePreferL1,
  cudaFuncCachePreferEqual
};

enum CudaDimentionIdx {
  kBlockDimX,
  kBlockDimY,
  kBlockDimZ,
  kBlockIdxX,
  kBlockIdxY,
  kBlockIdxZ,
  kThreadIdxX,
  kThreadIdxY,
  kThreadIdxZ
};

SgFunctionCallExp *BuildCudaCallFuncSetCacheConfig(
    SgFunctionSymbol *kernel,
    const CudaFuncCache cache_config);

enum CUDAMemcpyKind {
  cudaMemcpyHostToHost,
  cudaMemcpyHostToDevice,
  cudaMemcpyDeviceToHost,
  cudaMemcpyDeviceToDevice,
  cudaMemcpyDefault
};

SgFunctionCallExp *BuildCUDAMemcpy(SgExpression *dst,
                                   SgExpression *src,
                                   SgExpression *size,
                                   CUDAMemcpyKind kind);

SgVariableDeclaration *BuildDim3Declaration(const SgName &name,
                                            SgExpression *dimx,
                                            SgExpression *dimy,
                                            SgExpression *dimz,
                                            SgScopeStatement *scope);

SgCudaKernelCallExp *BuildCudaKernelCallExp(SgFunctionRefExp *func_ref,
                                            SgExprListExp *args,
                                            SgCudaKernelExecConfig *config);

SgCudaKernelExecConfig *BuildCudaKernelExecConfig(SgExpression *grid,
                                                  SgExpression *blocks,
                                                  SgExpression *shared = NULL,
                                                  SgExpression *stream = NULL);

SgExpression *BuildCudaIdxExp(const CudaDimentionIdx idx, SgGlobal *gs);

// Make a function a CUDA global function
void SetCUDAKernel(SgFunctionDeclaration *func);
// Make a function a CUDA device function
void SetCUDADevice(SgFunctionDeclaration *func);

} // namespace cuda
} // namespace translator
} // namespace kff



#endif

