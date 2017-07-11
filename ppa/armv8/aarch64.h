//---------------------------------------------------------------------------
// 
// Copyright (c) 2016, Freescale Semiconductor, Inc. All rights reserved.
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
//---------------------------------------------------------------------------

#ifndef _AARCH64_H
#define	_AARCH64_H

.equ  SPSR_MODE_MASK,  0x1F
.equ  SPSR_FOR_EL2H,   0x3C9
.equ  SPSR_FOR_EL1H,   0x3C5
.equ  SPSR_DAIF_MASK,  0x3C0
.equ  SPSR_MODE_EL2H,  0x009
.equ  SPSR_EL_MASK,    0xC
.equ  SPSR_EL0,        0x0
.equ  SPSR_EL1,        0x4
.equ  SPSR_EL2,        0x8
.equ  SPSR_EL3,        0xC
.equ  SPSR_EL3_M4,     0x10
.equ  SPSR_EL3_M4_32,  0x10

.equ  SPSR32_E_MASK,          0x200
.equ  SPSR32_E_BE,            0x200
.equ  SPSR32_DEFAULT,         0x1DA
.equ  SPSR32_EL2_LE,          0x1DA
.equ  SPSR32_EL2_BE,          0x3DA
.equ  SPSR32_EL1_LE,          0x1D3
.equ  SPSR32_EL1_BE,          0x3D3
.equ  SPSR32_MODE_HYP,        0xA
.equ  SPSR32_MODE_SUPV,       0x3
.equ  SPSR32_MODE_MASK,       0xF

.equ  SCTLR_EE_WXN_SA_A_MASK, 0x0208000A
.equ  SCTLR_EE_WXN_MASK,      0x02080000
.equ  SCTLR_EE_MASK,          0x02000000
.equ  SCTLR_EE_BE,            0x02000000
.equ  SCTLR_WXN_MASK,         0x00080000
.equ  SCTLR_I_C_M_MASK,       0x00001005
.equ  SCTLR_I_MASK,           0x00001000
.equ  SCTLR_SA_A_MASK,        0x0000000A
.equ  SCTLR_C_M_MASK,         0x00000005
.equ  SCTLR_SA_C_A_M_MASK,    0x0000000F
.equ  SCTLR_C_A_M_MASK,       0x00000007
.equ  SCTLR_SA_MASK,          0x00000008
.equ  SCTLR_C_MASK,           0x00000004
.equ  SCTLR_A_MASK,           0x00000002
.equ  SCTLR_M_MASK,           0x00000001
.equ  SCTLR_EL3_RES1,         0x30C50830       
.equ  SCTLR_EL2_RES1,         0x30C50830       
.equ  SCTLR_EL1_RES1,         0x30D00800       

.equ  CPTR_EL2_RES1_MASK,     0x33FF

.equ  DAIF_SET_MASK,          0x3C0

.equ  CPUECTLR_DISABLE_TWALK_PREFETCH,  0x4000000000
.equ  CPUECTLR_INS_PREFETCH_MASK,       0x1800000000
.equ  CPUECTLR_DAT_PREFETCH_MASK,       0x0300000000
.equ  CPUECTLR_SMPEN_MASK,              0x40
.equ  CPUECTLR_SMPEN_EN,                0x40
.equ  CPUECTLR_RET_MASK,                0x7
.equ  CPUECTLR_RET_SET,                 0x2
.equ  CPUECTLR_TIMER_MASK,              0x7
.equ  CPUECTLR_TIMER_8TICKS,            0x2

.equ  CPUACTLR_FRC_INORDER_MASK, 0x400000
.equ  CPUACTLR_FRC_INORDER_EN,   0x400000
.equ  CPUACTLR_ENDCCASCI_EN,     0x100000000000
.equ  CPUACTLR_DIS_LS_HW_PRE,    0x100000000000000

.equ  OSDLR_EL1_DLK_MASK,     0x1
.equ  OSDLR_EL1_DLK_LOCK,     0x1

.equ  HCR_EL2_RW_AARCH64,     0x80000000

.equ  ID_AA64PFR0_MASK_EL2,    0xF00
.equ  ID_AA64PFR0_EL2_64_ONLY, 0x100
.equ  ID_AA64PFR0_EL2_64OR32,  0x200

.equ  MPIDR_AFFINITY0_MASK,   0x00FF
.equ  MPIDR_AFFINITY0_OFFSET, 0x0
.equ  MPIDR_AFFINITY0_SIZE,   0x8
.equ  MPIDR_AFFINITY1_MASK,   0xFF00
.equ  MPIDR_AFFINITY1_OFFSET, 0x8
.equ  MPIDR_AFFINITY1_SIZE,   0x8
.equ  MPIDR_CORE_MASK,        0x00FF
.equ  MPIDR_CLUSTER_MASK,     0xFF00

 // masks and constants for midr_el1
.equ  MIDR_PARTNUM_MASK,       0xFFF0
.equ  MIDR_PARTNUM_START,      4
.equ  MIDR_PARTNUM_WIDTH,      12
.equ  MIDR_REVISION_START,     0
.equ  MIDR_REVISION_WIDTH,     4
.equ  MIDR_VARIANT_START,      20
.equ  MIDR_VARIANT_WIDTH,      4
.equ  MIDR_PARTNUM_A53,        0xD03
.equ  MIDR_PARTNUM_A57,        0xD07
.equ  MIDR_PARTNUM_A72,        0xD08
.equ  A53_DCACHE_RNPN_START,   0x03

.equ  SCR_FIQ_MASK,           0x4
.equ  SCR_IRQ_MASK,           0x2
.equ  SCR_RW_MASK,            0x400
.equ  SCR_RW_AARCH64,         0x400
.equ  SCR_EL3_4_EL2_AARCH32,  0x131
.equ  SCR_EL3_4_EL1_AARCH32,  0x031
.equ  SCR_EL3_HCE_EN,         0x100
.equ  SCR_EL3_SIF_DIS,        0x200
.equ  SCR_EL3_FIQ_EN,         0x4
.equ  SCR_EL3_NS_MASK,        0x1

.equ  SPSEL_SP,               0x1

.equ  CLEAN_DCACHE,           0x0
.equ  CLN_INV_DCACHE,         0x1

.equ  CNTP_CTL_EL0_EN,        0x1
.equ  CNTP_CTL_EL0_IMASK,     0x2
.equ  CNTP_CTL_EL0_ISTAT,     0x4

.equ   MODE_AARCH64_EL2,       0x0
.equ   MODE_AARCH64_EL1,       0x1
.equ   MODE_AARCH32_EL2,       0x2
.equ   MODE_AARCH32_EL1,       0x3
.equ   MODE_AARCH_MASK,        0x2
.equ   MODE_AARCH_64,          0x0
.equ   MODE_AARCH_32,          0x2
.equ   MODE_EL_MASK,           0x1
.equ   MODE_EL_2,              0x0
.equ   MODE_EL_1,              0x1

//-----------------------------------------------------------------------------

.macro m_get_core_pos _res, _reg1
     // out: _res = Core Number
     //		(Cluster_num * Core_per_cluster + Core_num)
     // uses: _res, _reg1
    mrs \_reg1, MPIDR_EL1

     // _res = Cluster_num
    ubfx \_res, \_reg1, #MPIDR_AFFINITY1_OFFSET, #MPIDR_AFFINITY1_SIZE
    ldr \_reg1, =CPU_PER_CLUSTER

     // _res = CPU_PER_CLUSTER * Cluster
    mul \_res, \_reg1, \_res

    mrs \_reg1, MPIDR_EL1
     // _reg1 = Core_num
    ubfx \_reg1, \_reg1, #MPIDR_AFFINITY0_OFFSET, #MPIDR_AFFINITY0_SIZE

     // _res = (Cluster_num * Core_per_cluster + Core_num)
    add \_res, \_res, \_reg1

.endm

//-----------------------------------------------------------------------------

.macro m_get_core_stack_top _res, _core, _reg1
     // in: _core = Core Number in a register
     // out: _res = Stack Top of Core _core
     // uses: _res, _reg1

     // Get absolute address of STACKS TOP in case
     // of position independent code

     // Using ADRP intruction to access +/- 4GB Address
     // ADR would only give address within +/- 1MB
     // :lo12: gives lower 4KB offset within page
    adrp \_reg1, __STACKS_TOP__
    add \_reg1, \_reg1, :lo12:__STACKS_TOP__

     // Get SP for individual core. Core0 gets
     // SP as Stack_top
     // _res = Stack_top - Core_num * Stack_per_core
    ldr \_res, =__STACK_SIZE_PER_CPU_
    msub \_res, \_res, \_core, \_reg1
.endm

//-----------------------------------------------------------------------------

.macro m_get_cur_stack_top _res _reg1 _reg2
     // out: _res = SP for Current Core
     // uses: _res, _reg1, _reg2
    m_get_core_pos \_reg1, \_reg2
    m_get_core_stack_top \_res, \_reg1, \_reg2
.endm

//-----------------------------------------------------------------------------

#define CPUECTLR_EL1  S3_1_C15_C2_1
#define CPUACTLR_EL1  S3_1_C15_C2_0

//-----------------------------------------------------------------------------


#endif // _AARCH64_H
