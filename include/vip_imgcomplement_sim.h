/*
 *  VIP_IMGCOMPLEMENT_SIM.H - simulation helper functions for Image Complement
 *
 *  Copyright 1995-2003 The MathWorks, Inc.
 */

#ifndef vip_imgcomplement_sim_h
#define vip_imgcomplement_sim_h

/* DSPSIM_PadArgsCache is a structure used to contain parameters/arguments
 * for each of the individual simulation functions listed below.
 */

typedef struct {
    int_T       NumberOfPorts; 
} VIPSIM_ImgComplementArgsCache;

/* Simulation helper functions to handle Image Complement */

extern void VIPSIM_ImgComplement_D(SimStruct *S, VIPSIM_ImgComplementArgsCache *args);

extern void VIPSIM_ImgComplement_R(SimStruct *S, VIPSIM_ImgComplementArgsCache *args);

extern void VIPSIM_ImgComplement_U8(SimStruct *S, VIPSIM_ImgComplementArgsCache *args);

extern void VIPSIM_ImgComplement_B(SimStruct *S, VIPSIM_ImgComplementArgsCache *args);

#endif /* vip_imgcomplement_sim_h */

/* [EOF] vip_imgcomplement_sim.h */
