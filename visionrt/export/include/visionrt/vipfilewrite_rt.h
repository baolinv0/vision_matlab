/*
 *  vipfilewrite_rt.h
 *
 *  Copyright 1995-2005 The MathWorks, Inc.
 */

#ifndef vipfilewrite_rt_h
#define vipfilewrite_rt_h

#include "dsp_rt.h"
#include "libmwvisionrt_util.h"

/* datatype double */
#ifdef __cplusplus
extern "C" {
#endif
 
LIBMWVISIONRT_API void MWVIP_AYUV_WriteLine(void *fptrDW,
							 const byte_T *portAddr0,
							 const byte_T *portAddr1,
							 const byte_T *portAddr2,
							 const byte_T *portAddr3,
							 int_T rows, 
							 int_T cols);


LIBMWVISIONRT_API void MWVIP_UYVY_WriteLine(void *fptrDW,
							 const byte_T *portAddr0,
							 const byte_T *portAddr1,
							 const byte_T *portAddr2,
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API void MWVIP_IUYV_WriteLine(void *fptrDW,
							 const byte_T *portAddr0,
							 const byte_T *portAddr1,
							 const byte_T *portAddr2,
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API void MWVIP_YUY2_WriteLine(void *fptrDW,
							 const byte_T *portAddr0,
							 const byte_T *portAddr1,
							 const byte_T *portAddr2,
							 int_T rows, 
							 int_T cols);

 
LIBMWVISIONRT_API void MWVIP_YVYU_WriteLine(void *fptrDW,
							 const byte_T *portAddr0,
							 const byte_T *portAddr1,
							 const byte_T *portAddr2,
							 int_T rows, 
							 int_T cols);


LIBMWVISIONRT_API void MWVIP_Y41P_WriteLine(void *fptrDW,
							 const byte_T *portAddr0,
							 const byte_T *portAddr1,
							 const byte_T *portAddr2,
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API void MWVIP_Y41T_WriteLine(void *fptrDW,
							 const byte_T *portAddr0,
							 const byte_T *portAddr1,
							 const byte_T *portAddr2,
							 const byte_T *portAddr3,
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API void MWVIP_Y42T_WriteLine(void *fptrDW,
							 const byte_T *portAddr0,
							 const byte_T *portAddr1,
							 const byte_T *portAddr2,
							 const byte_T *portAddr3,
							 int_T rows, 
							 int_T cols);

 
LIBMWVISIONRT_API void MWVIP_CLJR_WriteLine(void *fptrDW,
							 const byte_T *portAddr0,
							 const byte_T *portAddr1,
							 const byte_T *portAddr2,
							 int_T rows, 
							 int_T cols);


LIBMWVISIONRT_API void MWVIP_IYU1_WriteLine(void *fptrDW,
							 const byte_T *portAddr0,
							 const byte_T *portAddr1,
							 const byte_T *portAddr2,
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API void MWVIP_IYU2_WriteLine(void *fptrDW,
							 const byte_T *portAddr0,
							 const byte_T *portAddr1,
							 const byte_T *portAddr2,
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API void MWVIP_V210_WriteBits(void *fptrDW, const uint16_T *p0, 
											  const uint16_T *p1, const uint16_T *p2);

 
LIBMWVISIONRT_API void MWVIP_V210_WriteLine(void *fptrDW,
							 const void *portAddr0,
							 const void *portAddr1,
							 const void *portAddr2,
							 int_T rows, 
							 int_T cols);


LIBMWVISIONRT_API void MWVIP_oneInport_WriteLine(void *fptrDW,
							 const void *portAddr0,
							 int_T rows, 
							 int_T cols,
							 int_T bpe);

LIBMWVISIONRT_API void MWVIP_oneInport_WriteLine_CG(void *fptrDW,
							 const void *portAddr0,
							 int_T rows, 
							 int_T cols,
							 int_T bpe);

LIBMWVISIONRT_API void MWVIP_twoInports_WriteLine(void *fptrDW,
							 const byte_T *portAddr1,
							 const byte_T *portAddr2,
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API void MWVIP_WriteByteSwapN(int_T N, const byte_T *data, byte_T *out);


LIBMWVISIONRT_API void MWVIP_oneInport_WriteLine_BS(void *fptrDW,
							 const void *portAddr0,
							 int_T rows, 
							 int_T cols,
							 int_T bpe);

LIBMWVISIONRT_API void MWVIP_oneInport_WriteLine_BS_CG(void *fptrDW,
							 const void *portAddr0,
							 int_T rows, 
							 int_T cols,
							 int_T bpe);

LIBMWVISIONRT_API void MWVIP_fullByteWrite_PACKED_TLF(void *fptrDW,
										   const void *portAddr0,
										   const void *portAddr1,
										   const void *portAddr2,
										   const void *portAddr3,
										   const uint8_T **tmpInPtrs,
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpe,   
										   int32_T *bpeout,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStart,
								           int_T iIncr);

LIBMWVISIONRT_API void MWVIP_fullByteWrite_PACKED_TLF_BS(void *fptrDW,
										   const void *portAddr0,
										   const void *portAddr1,
										   const void *portAddr2,
										   const void *portAddr3,
										   const uint8_T **tmpInPtrs,
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpe,   
										   int32_T *bpeout,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStart,
								           int_T iIncr);

LIBMWVISIONRT_API void MWVIP_fullByteWrite_PACKED_BLF(void *fptrDW,
										   const void *portAddr0,
										   const void *portAddr1,
										   const void *portAddr2,
										   const void *portAddr3,
										   const uint8_T **tmpInPtrs,
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpe,   
										   int32_T *bpeout,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStartOff,
								           int_T iDecr);

LIBMWVISIONRT_API void MWVIP_fullByteWrite_PACKED_BLF_BS(void *fptrDW,
										   const void *portAddr0,
										   const void *portAddr1,
										   const void *portAddr2,
										   const void *portAddr3,
										   const uint8_T **tmpInPtrs,
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpe,   
										   int32_T *bpeout,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStartOff,
								           int_T iDecr);

LIBMWVISIONRT_API void MWVIP_fullByteWrite_PACKED_TLF_CG(void *fptrDW,
										   const void *portAddr0,
										   const void *portAddr1,
										   const void *portAddr2,
										   const void *portAddr3,
										   const uint8_T **tmpInPtrs,
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpe,   
										   int32_T *bpeout,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStart,
								           int_T iIncr);

LIBMWVISIONRT_API void MWVIP_fullByteWrite_PACKED_TLF_BS_CG(void *fptrDW,
										   const void *portAddr0,
										   const void *portAddr1,
										   const void *portAddr2,
										   const void *portAddr3,
										   const uint8_T **tmpInPtrs,
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpe,   
										   int32_T *bpeout,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStart,
								           int_T iIncr);

LIBMWVISIONRT_API void MWVIP_fullByteWrite_PACKED_BLF_CG(void *fptrDW,
										   const void *portAddr0,
										   const void *portAddr1,
										   const void *portAddr2,
										   const void *portAddr3,
										   const uint8_T **tmpInPtrs,
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpe,   
										   int32_T *bpeout,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStartOff,
								           int_T iDecr);

LIBMWVISIONRT_API void MWVIP_fullByteWrite_PACKED_BLF_BS_CG(void *fptrDW,
										   const void *portAddr0,
										   const void *portAddr1,
										   const void *portAddr2,
										   const void *portAddr3,
										   const uint8_T **tmpInPtrs,
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpe,   
										   int32_T *bpeout,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStartOff,
								           int_T iDecr);


LIBMWVISIONRT_API void MWVIP_loopZeroWrite(void *fptrDW,
							  int_T cols);
LIBMWVISIONRT_API boolean_T MWVIP_OpenWriteAndCheckIfFileExists(void *fptrDW, const char *FileName);
LIBMWVISIONRT_API void MWVIP_WriteFclose(void *fptrDW);
LIBMWVISIONRT_API void MWVIP_castDoubleToFix(const real_T *uin, void *dworkPtrO, int_T inWidth, int_T dtIdx);


#ifdef __cplusplus
} /*  close brace for extern C from above */
#endif

#endif /* vipfilewrite_rt_h */

/* [EOF] vipfilewrite_rt.h */
