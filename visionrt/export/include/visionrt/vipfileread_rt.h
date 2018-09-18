/*
 *  vipfileread_rt.h
 *
 *  Copyright 1995-2005 The MathWorks, Inc.
 */

#ifndef vipfileread_rt_h
#define vipfileread_rt_h

#include "dsp_rt.h"
#include "libmwvisionrt_util.h"

/* datatype double */
#ifdef __cplusplus
extern "C" {
#endif
 
LIBMWVISIONRT_API boolean_T MWVIP_AYUV_ReadLine(void *fptrDW,
							 uint8_T *portAddr0,
							 uint8_T *portAddr1,
							 uint8_T *portAddr2,
							 uint8_T *portAddr3,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols);


LIBMWVISIONRT_API boolean_T MWVIP_UYVY_ReadLine(void *fptrDW,
							 uint8_T *portAddr0,
							 uint8_T *portAddr1,
							 uint8_T *portAddr2,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API boolean_T MWVIP_IUYV_ReadLine(void *fptrDW,
							 uint8_T *portAddr0,
							 uint8_T *portAddr1,
							 uint8_T *portAddr2,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API boolean_T MWVIP_YUY2_ReadLine(void *fptrDW,
							 uint8_T *portAddr0,
							 uint8_T *portAddr1,
							 uint8_T *portAddr2,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols);

 
LIBMWVISIONRT_API boolean_T MWVIP_YVYU_ReadLine(void *fptrDW,
							 uint8_T *portAddr0,
							 uint8_T *portAddr1,
							 uint8_T *portAddr2,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols);


LIBMWVISIONRT_API boolean_T MWVIP_Y41P_ReadLine(void *fptrDW,
							 uint8_T *portAddr0,
							 uint8_T *portAddr1,
							 uint8_T *portAddr2,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API boolean_T MWVIP_Y41T_ReadLine(void *fptrDW,
							 uint8_T *portAddr0,
							 uint8_T *portAddr1,
							 uint8_T *portAddr2,
							 uint8_T *portAddr3,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API boolean_T MWVIP_Y42T_ReadLine(void *fptrDW,
							 uint8_T *portAddr0,
							 uint8_T *portAddr1,
							 uint8_T *portAddr2,
							 uint8_T *portAddr3,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols);

 
LIBMWVISIONRT_API boolean_T MWVIP_CLJR_ReadLine(void *fptrDW,
							 uint8_T *portAddr0,
							 uint8_T *portAddr1,
							 uint8_T *portAddr2,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols);


LIBMWVISIONRT_API boolean_T MWVIP_IYU1_ReadLine(void *fptrDW,
							 uint8_T *portAddr0,
							 uint8_T *portAddr1,
							 uint8_T *portAddr2,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API boolean_T MWVIP_IYU2_ReadLine(void *fptrDW,
							 uint8_T *portAddr0,
							 uint8_T *portAddr1,
							 uint8_T *portAddr2,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API void MWVIP_V210_ReadBits(void *fptrDW, uint16_T *p0, uint16_T *p1, uint16_T *p2);

 
LIBMWVISIONRT_API boolean_T MWVIP_V210_ReadLine(void *fptrDW,
							 void *portAddr0,
							 void *portAddr1,
							 void *portAddr2,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols);


LIBMWVISIONRT_API boolean_T MWVIP_oneOutport_ReadLine(void *fptrDW,
							 void *portAddr0,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols,
							 int_T bpe);

LIBMWVISIONRT_API boolean_T MWVIP_twoOutports_ReadLine(void *fptrDW,
							 uint8_T *portAddr1,
							 uint8_T *portAddr2,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols);

LIBMWVISIONRT_API void MWVIP_byteSwapN(int_T N, byte_T *data);


LIBMWVISIONRT_API boolean_T MWVIP_oneOutport_ReadLine_BS(void *fptrDW,
							 void *portAddr0,
							 int32_T   *numLoops,
							 boolean_T *eofflag, 
							 int_T rows, 
							 int_T cols,
							 int_T bpe);

LIBMWVISIONRT_API boolean_T MWVIP_fullByteRead_PACKED_TLF(void *fptrDW,
										   void *portAddr0,
										   void *portAddr1,
										   void *portAddr2,
										   void *portAddr3,
										   uint8_T **tmpOutPtrs,/* uint8_T *tmpOutPtrs[] */
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int32_T   *numLoops,
										   boolean_T *eofflag, 
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpe,   
										   int32_T *bpeout,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStart,
								           int_T iIncr);

LIBMWVISIONRT_API boolean_T MWVIP_fullByteRead_PACKED_TLF_BS(void *fptrDW,
										   void *portAddr0,
										   void *portAddr1,
										   void *portAddr2,
										   void *portAddr3,
										   uint8_T **tmpOutPtrs,/* uint8_T *tmpOutPtrs[], */  
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int32_T   *numLoops,
										   boolean_T *eofflag, 
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpe,   
										   int32_T *bpeout,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStart,
								           int_T iIncr);

LIBMWVISIONRT_API boolean_T MWVIP_fullByteRead_PACKED_BLF(void *fptrDW,
										   void *portAddr0,
										   void *portAddr1,
										   void *portAddr2,
										   void *portAddr3,
										   uint8_T **tmpOutPtrs,/* uint8_T *tmpOutPtrs[] */
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int32_T   *numLoops,
										   boolean_T *eofflag, 
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpe,   
										   int32_T *bpeout,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStartOff,
								           int_T iDecr);

LIBMWVISIONRT_API boolean_T MWVIP_fullByteRead_PACKED_BLF_BS(void *fptrDW,
										   void *portAddr0,
										   void *portAddr1,
										   void *portAddr2,
										   void *portAddr3,
										   uint8_T **tmpOutPtrs,/* uint8_T *tmpOutPtrs[] */
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int32_T   *numLoops,
										   boolean_T *eofflag, 
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpe,   
										   int32_T *bpeout,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStartOff,
								           int_T iDecr);

LIBMWVISIONRT_API uint8_T MWVIP_getValuelessthan8bits(void *fptrDW, int_T numbits, 
							  byte_T currentChar, int32_T leftoverBits);

LIBMWVISIONRT_API void MWVIP_getValue(void *fptrDW, void **tmpOutPtrs, int32_T *bitspe, int_T c, 
			  byte_T currentChar, int32_T leftoverBits);

LIBMWVISIONRT_API boolean_T MWVIP_bitsRead_PACKED_TLF(void *fptrDW,
										   uint8_T *portAddr0,
										   uint8_T *portAddr1,
										   uint8_T *portAddr2,
										   uint8_T *portAddr3,
										   uint8_T **tmpOutPtrs,/* uint8_T *tmpOutPtrs[] */
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int32_T   *numLoops,
										   boolean_T *eofflag, 
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpeout,
										   int32_T *bitspe,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStart,
								           int_T iIncr,
										   byte_T   currentChar,
                                           int32_T  leftoverBits);
LIBMWVISIONRT_API boolean_T MWVIP_bitsRead_PACKED_BLF(void *fptrDW,
										   uint8_T *portAddr0,
										   uint8_T *portAddr1,
										   uint8_T *portAddr2,
										   uint8_T *portAddr3,
										   uint8_T **tmpOutPtrs,/* uint8_T *tmpOutPtrs[] */
										   int32_T *offsetC,
										   int32_T *offsetP,
										   int32_T   *numLoops,
										   boolean_T *eofflag, 
										   int_T rows, 
										   int_T cols,										   
										   int32_T *bpeout,
										   int32_T *bitspe,
										   int32_T *ctoport,
										   int_T numCompPerPack,
										   int_T iStartOff,
								           int_T iDecr,
										   byte_T   currentChar,
                                           int32_T  leftoverBits);
LIBMWVISIONRT_API boolean_T MWVIP_handleFilePtr(void *fptrDW,
							  int32_T   *numLoops,
							  boolean_T *eofflag, 
							  int_T cols);
LIBMWVISIONRT_API void MWVIP_handleFilePtr2(void *fptrDW,
							  int32_T   *numLoops,
							  boolean_T *eofflag);
LIBMWVISIONRT_API boolean_T MWVIP_OpenAndCheckIfFileExists(void *fptrDW, const char *FileName);
LIBMWVISIONRT_API void MWVIP_FileReadRewind(void *fptrDW);
LIBMWVISIONRT_API void MWVIP_FileReadFclose(void *fptrDW);
LIBMWVISIONRT_API void MWVIP_castIntToFloat(real_T *yfloat, int_T N, int_T inc, int_T dtIdx);

LIBMWVISIONRT_API void MWVIP_set4thBytefor24Bits_BE(void *yO, int_T N, boolean_T signedData, int_T inc);
LIBMWVISIONRT_API void MWVIP_set4thBytefor24Bits_LE(void *yO, int_T N, boolean_T signedData, int_T inc);


#ifdef __cplusplus
} /*  close brace for extern C from above */
#endif

#endif /* vipfileread_rt_h */
