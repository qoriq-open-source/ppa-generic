//---------------------------------------------------------------------------
// 
// Copyright 2017 NXP Semiconductor
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// 
// Author Rod Dorris <rod.dorris@nxp.com>
// 
//---------------------------------------------------------------------------

#ifndef _GICV2_H
#define	_GICV2_H

//-----------------------------------------------------------------------------

 // register offsets
#define GICD_CTLR_OFFSET          0x0
#define GICD_CPENDSGIR3_OFFSET    0xF1C
#define GICD_SPENDSGIR3_OFFSET    0xF2C
#define GICD_SGIR_OFFSET          0xF00
#define GICD_IGROUPR0_OFFSET      0x080
#define GICD_TYPER_OFFSET         0x0004
#define GICD_ISENABLER0_OFFSET    0x0100
#define GICD_ICENABLER0_OFFSET    0x0180
#define GICD_IPRIORITYR3_OFFSET   0x040C
#define GICD_ISENABLERn_OFFSET    0x0100
#define GICD_ISACTIVER0_OFFSET    0x300

#define GICC_CTLR_OFFSET          0x0
#define GICC_PMR_OFFSET           0x0004
#define GICC_IAR_OFFSET           0x000C
#define GICC_DIR_OFFSET           0x1000
#define GICC_EOIR_OFFSET          0x0010

 // bitfield masks
#define GICC_CTLR_EN_GRP0           0x1
#define GICC_CTLR_EN_GRP1           0x2
#define GICC_CTLR_EOImodeS_MASK     0x200
#define GICC_CTLR_DIS_BYPASS        0x60
#define GICC_CTLR_CBPR_MASK         0x10
#define GICC_CTLR_FIQ_EN_MASK       0x8
#define GICC_CTLR_ACKCTL_MASK       0x4
#define GICC_PMR_FILTER             0xFF

#define GICD_CTLR_EN_GRP0           0x1
#define GICD_CTLR_EN_GRP1           0x2
#define GICD_IGROUP0_SGI15          0x8000 
#define GICD_ISENABLE0_SGI15        0x8000 
#define GICD_ICENABLE0_SGI15        0x8000 
#define GICD_ISACTIVER0_SGI15       0x8000 
#define GICD_CPENDSGIR_CLR_MASK     0xFF000000
#define GICD_IPRIORITY_SGI15_MASK   0xFF000000
#define GICD_SPENDSGIR3_SGI15_MASK  0xFF000000
#define GICD_SPENDSGIR3_SGI15_OFFSET  0x18


#endif // _GICV2_H
