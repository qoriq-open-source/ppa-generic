// 
// ARM v8 AArch64 PSCI v1.0
//
// Copyright (c) 2013-2015 Freescale Semiconductor, Inc. All rights reserved.
//

// This file includes:
// (1) PSCI functions SMC64 interface
// (2) PSCI functions SMC32 interface

//-----------------------------------------------------------------------------

  .section .text, "ax"

//-----------------------------------------------------------------------------

#include "aarch64.h"
#include "soc.h"
#include "soc.mac"
#include "psci.h"

//-----------------------------------------------------------------------------

.global _smc64_std_svc
.global _smc32_std_svc
.global _initialize_psci
.global _find_core
.global _cpu0_data

//-----------------------------------------------------------------------------

 // Note: x11 contains the function number
 //       x12 is used to save/restore the LR

_smc64_std_svc:
     // psci smc64 interface lives here

     // is this CPU_SUSPEND
    ldr  x10, =PSCI64_CPU_SUSPEND_ID
    and  w10, w10, #PSCI_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc64_psci_cpu_suspend

     // is this CPU_ON
    ldr  x10, =PSCI64_CPU_ON_ID
    and  w10, w10, #PSCI_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc64_psci_cpu_on

     // is this AFFINITY_INFO
    ldr  x10, =PSCI32_AFFINITY_INFO_ID
    and  w10, w10, #PSCI_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc64_psci_affinity_info

     // if we are here then we have an unimplemented/unrecognized function
    b _smc_unimplemented

//-----------------------------------------------------------------------------

 // Note: x11 contains the function number

_smc32_std_svc:
     // psci smc32 interface lives here

     // is this PSCI_VERSION
    ldr  x10, =PSCI_VERSION_ID
    and  w10, w10, #PSCI_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc32_psci_version

     // is this CPU_SUSPEND
    ldr  x10, =PSCI32_CPU_SUSPEND_ID
    and  w10, w10, #PSCI_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc64_psci_cpu_suspend

     // is this CPU_OFF
    ldr  x10, =PSCI_CPU_OFF_ID
    and  w10, w10, #PSCI_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc32_psci_cpu_off

     // is this CPU_ON
    ldr  x10, =PSCI32_CPU_ON_ID
    and  w10, w10, #PSCI_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc64_psci_cpu_on

     // is this SYSTEM_OFF
    ldr  x10, =PSCI_SYSTEM_OFF
    and  w10, w10, #PSCI_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc32_psci_system_off

     // is this SYSTEM_RESET
    ldr  x10, =PSCI_SYSTEM_RESET_ID
    and  w10, w10, #PSCI_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc32_psci_system_reset

     // is this PSCI_FEATURES
    ldr  x10, =PSCI_FEATURES_ID
    and  w10, w10, #PSCI_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc32_psci_features

     // is this AFFINITY_INFO
    ldr  x10, =PSCI32_AFFINITY_INFO_ID
    and  w10, w10, #PSCI_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc64_psci_affinity_info

     // if we are here then we have an unimplemented/unrecognized function
    b _smc_unimplemented

//-----------------------------------------------------------------------------

smc64_psci_cpu_suspend:
     // x0 = function id
     // x1 = power state
     // x2 = entry point address
     // x3 = context id
    mov  x12, x30
    mov  x8, x1
    mov  x9, x2
    mov  x10, x3
     // x8  = power state
     // x9  = entry point address
     // x10 = context id

     // check parameters
    ldr  x0, =POWER_STATE_MASK
    mvn  x0, x0
    and  x0, x1, x0
    cbnz x0, psci_invalid

     // power level
    ldr  x0, =POWER_LEVEL_MASK
    and  x0, x1, x0
    lsr  x0, x0, #24
    cmp  x0, #PWR_STATE_CORE_LVL
    b.eq power_state_core
    cmp  x0, #PWR_STATE_CLUSTER_LVL
    b.eq power_state_cluster
    cmp  x0, #PWR_STATE_SYSTEM_LVL
    b.eq power_state_system
    b    psci_invalid

 // if it is a core power state
power_state_core:
     // x8  = power state
     // x9  = entry point address
     // x10 = context id

    ldr  x0, =STATE_TYPE_MASK
    and  x0, x8, x0
    lsr  x0, x0, #16

    cmp  x0, #PWR_STATE_STANDBY
    b.eq core_in_standby
    cmp  x0, #PWR_STATE_PWR_DOWN
    b.eq core_in_powerdown
     // else we have an invalid parameter
    b    psci_invalid

core_in_standby:
     // see if this functionality is supported in the soc-specific code
    mov  x7, #SOC_CORE_STANDBY
    cbz  x7, psci_unimplemented

    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb
    mov  x11, x0
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_STANDBY
    bl   _setCoreData

     // save cpuectlr
    mov  x0, x11
    mov  x1, #CPUECTLR_DATA
    mrs  x2, CPUECTLR_EL1
    bl   _setCoreData

     // x11 = core mask lsb

     // put the core into standby
    mov  x0, x11
    bl   _soc_core_entr_stdby

     // cleanup after the core exits standby
    mov  x0, x11
    bl   _soc_core_exit_stdby

    mov  x0, x11
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_RELEASED
    bl   _setCoreData

     // restore cpuectlr
    mov  x0, x11
    mov  x1, #CPUECTLR_DATA
    bl   _getCoreData
    msr  CPUECTLR_EL1, x0

    b    psci_success

core_in_powerdown:
     // see if this functionality is supported in the soc-specific code
    mov  x7, #SOC_CORE_PWR_DWN
    cbz  x7, psci_unimplemented

     // x9  = entry point address
     // x10 = context id

    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb
    mov  x11, x0
    mov  x1, #CNTXT_ID_DATA
    mov  x2, x10
    bl   _setCoreData

     // x9  = entry point address
     // x11 = core mask lsb

     // save entry point address
    mov  x0, x11
    mov  x1, #START_ADDR_DATA
    mov  x2, x9
    bl   _setCoreData

     // x11 = core mask lsb

    mov  x0, x11
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_PWR_DOWN
    bl   _setCoreData

     // save cpuectlr
    mov  x0, x11
    mov  x1, #CPUECTLR_DATA
    mrs  x2, CPUECTLR_EL1
    bl   _setCoreData

     // enter power-down
    mov  x0, x11
    bl   _soc_core_entr_pwrdn

     // x11 = core mask lsb

    mov  x0, x11
    bl   _soc_core_exit_pwrdn

    mov  x0, x11
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_RELEASED
    bl   _setCoreData

     // restore cpuectlr
    mov  x0, x11
    mov  x1, #CPUECTLR_DATA
    bl   _getCoreData
    msr  CPUECTLR_EL1, x0

     // x11 = core mask lsb

     // return to entry point address
    mov  x0, x11
    mov  x1, #START_ADDR_DATA
    bl   _getCoreData
    msr  ELR_EL3, x0

    mov  x0, x11
    mov  x1, #CNTXT_ID_DATA
    bl   _getCoreData

     // we have a context id in x0 - don't overwrite this
     // with a status return code
    b    psci_completed

     //------------------------------------------

 // if it is a cluster power state
power_state_cluster:
     // x8  = power state
     // x9  = entry point address
     // x10 = context id

     // get mpidr, extract cluster number
    mrs  x0, mpidr_el1
    and  x0, x0, #MPIDR_CLUSTER_MASK

     // x0 = cluster number in mpidr format

     // see if this is the last active core of the cluster
    bl   _core_on_cnt_clstr

     // if this is not the last active core of the cluster, return with error
    cmp  x0, #1
    b.gt psci_invalid

     // determine the power level
    ldr  x0, =STATE_TYPE_MASK
    and  x0, x8, x0
    lsr  x0, x0, #16

    cmp  x0, #PWR_STATE_STANDBY
    b.eq cluster_in_stdby
    cmp  x0, #PWR_STATE_PWR_DOWN
    b.eq cluster_in_pwrdn
     // else we have an invalid parameter
    b    psci_invalid

cluster_in_stdby:
     // see if this functionality is supported in the soc-specific code
    mov  x7, #SOC_CLUSTER_STANDBY
    cbz  x7, psci_unimplemented

     // to put the cluster in stdby, we also have to 
     // put this core in stdby
    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb
    mov  x11, x0
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_STANDBY
    bl   _setCoreData

     // save cpuectlr
    mov  x0, x11
    mov  x1, #CPUECTLR_DATA
    mrs  x2, CPUECTLR_EL1
    bl   _setCoreData

     // x11 = core mask lsb

    mov  x0, x11
    bl   _soc_clstr_entr_stdby

     // cleanup after the cluster exits standby
    mov  x0, x11
    bl   _soc_clstr_exit_stdby

    mov  x0, x11
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_RELEASED
    bl   _setCoreData

     // restore cpuectlr
    mov  x0, x11
    mov  x1, #CPUECTLR_DATA
    bl   _getCoreData
    msr  CPUECTLR_EL1, x0

    b    psci_success

cluster_in_pwrdn:
     // see if this functionality is supported in the soc-specific code
    mov  x7, #SOC_CLUSTER_PWR_DWN
    cbz  x7, psci_unimplemented

     // x9  = entry point address
     // x10 = context id

    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb
    mov  x11, x0
    mov  x1, #CNTXT_ID_DATA
    mov  x2, x10
    bl   _setCoreData

     // x9  = entry point address
     // x11 = core mask

     // save entry point address
    mov  x0, x11
    mov  x1, #START_ADDR_DATA
    mov  x2, x9
    bl   _setCoreData

     // x11 = core mask

     // to put the cluster in power down, we also
     // have to power-down this core
    mov  x0, x11
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_PWR_DOWN
    bl   _setCoreData

     // save cpuectlr
    mov  x0, x11
    mov  x1, #CPUECTLR_DATA
    mrs  x2, CPUECTLR_EL1
    bl   _setCoreData

    mov  x0, x11
    bl   _soc_clstr_entr_pwrdn

     // cleanup after the cluster exits power-down
    mov  x0, x11
    bl   _soc_clstr_exit_pwrdn

    mov  x0, x11
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_RELEASED
    bl   _setCoreData

     // restore cpuectlr
    mov  x0, x11
    mov  x1, #CPUECTLR_DATA
    bl   _getCoreData
    msr  CPUECTLR_EL1, x0

     // return to entry point address
    mov  x0, x11
    mov  x1, #START_ADDR_DATA
    bl   _getCoreData
    msr  ELR_EL3, x0

    mov  x0, x11
    mov  x1, #CNTXT_ID_DATA
    bl   _getCoreData

     // we have a context id in x0 - don't overwrite this
     // with a status return code
    b    psci_completed

     //------------------------------------------

 // if it is a system power state
power_state_system:
     // x8  = power state
     // x9  = entry point address
     // x10 = context id

     // see if this is the last active core of the system
    bl   core_on_cnt_sys

     // if this is not the last active core of the system, return with error
    cmp  x0, #1
    b.gt  psci_invalid

     // determine the power level
    ldr  x0, =STATE_TYPE_MASK
    and  x0, x8, x0
    lsr  x0, x0, #16

    cmp  x0, #PWR_STATE_STANDBY
    b.eq system_in_stdby
    cmp  x0, #PWR_STATE_PWR_DOWN
    b.eq system_in_pwrdn
     // else we have an invalid parameter
    b    psci_invalid

system_in_stdby:
     // see if this functionality is supported in the soc-specific code
    mov  x7, #SOC_SYSTEM_STANDBY
    cbz  x7, psci_unimplemented

     // to put the system in stdby, we also have to 
     // put this core in stdby
    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb
    mov  x11, x0
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_STANDBY
    bl   _setCoreData

     // save cpuectlr
    mov  x0, x11
    mov  x1, #CPUECTLR_DATA
    mrs  x2, CPUECTLR_EL1
    bl   _setCoreData

     // x11 = core mask lsb

    mov  x0, x11
    bl   _soc_sys_entr_stdby

     // cleanup after the system exits standby
    mov  x0, x11
    bl   _soc_sys_exit_stdby

    mov  x0, x11
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_RELEASED
    bl   _setCoreData

     // restore cpuectlr
    mov  x0, x11
    mov  x1, #CPUECTLR_DATA
    bl   _getCoreData
    msr  CPUECTLR_EL1, x0

    b    psci_success

system_in_pwrdn:
     // see if this functionality is supported in the soc-specific code
    mov  x7, #SOC_SYSTEM_PWR_DWN
    cbz  x7, psci_unimplemented

     // x9  = entry point address
     // x10 = context id

    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb
    mov  x11, x0
    mov  x1, #CNTXT_ID_DATA
    mov  x2, x10
    bl   _setCoreData

     // x9  = entry point address
     // x11 = core mask

     // save entry point address
    mov  x0, x11
    mov  x1, #START_ADDR_DATA
    mov  x2, x9
    bl   _setCoreData

     // x11 = core mask

    mov  x0, x11
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_PWR_DOWN
    bl   _setCoreData

     // save cpuectlr
    mov  x0, x11
    mov  x1, #CPUECTLR_DATA
    mrs  x2, CPUECTLR_EL1
    bl   _setCoreData

    mov  x0, x11
    bl   _soc_sys_entr_pwrdn
     // we have an return status code in x0
    mov  x6, x0

     // cleanup after the system exits power-down
    mov  x0, x11
    bl   _soc_sys_exit_pwrdn

     // x11 = core mask lsb

    mov  x0, x11
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_RELEASED
    bl   _setCoreData

     // restore cpuectlr
    mov  x0, x11
    mov  x1, #CPUECTLR_DATA
    bl   _getCoreData
    msr  CPUECTLR_EL1, x0

     // if we have an error, return to the caller rather
     // than the entry point address
    cbz  x6, 1f
    b    psci_failure

1:
     // return to entry point address
    mov  x0, x11
    mov  x1, #START_ADDR_DATA
    bl   _getCoreData
    msr  ELR_EL3, x0

    mov  x0, x11
    mov  x1, #CNTXT_ID_DATA
    bl   _getCoreData

     // we have a context id in x0 - don't overwrite this
     // with a status return code
    b    psci_completed

//-----------------------------------------------------------------------------

smc64_psci_cpu_on:
     // x0   = function id 
     // x1   = target cpu (mpidr)
     // x2   = start address
     // x3   = context id

	 // save the LR
    mov  x12, x30

	 // save input parms
	mov  x6, x1
    mov  x7, x2
    mov  x8, x3

     // get EL level of caller
     // error return if not EL1 or EL2
    mrs   x0, spsr_el3
    mov   x4, x0
    bl   _getCallerEL
    cbz  x0, psci_denied

     // x4   = spsr_el3 of caller
     // x6   = target cpu (mpidr)
     // x7   = start address
     // x8   = context id

     // get the core mask
    mov  x0, x6
    bl   _get_core_mask_lsb
    cbnz x0, 4f
     // we have an invalid parameter (mpidr)
    b    psci_invalid
4:
    mov  x6, x0

     // ck for 32-bit aligned start address
    tst  x7, #ALIGNED_32BIT_MASK
    b.eq 5f    
     // we have an invalid parameter (misaligned address)
    b    psci_invalid
5:
     // x4   = spsr_el3 of caller
     // x6   = core mask (lsb)
     // x7   = start address
     // x8   = context id

     // check if core disabled
    bl   _soc_ck_disabled
    cbnz w0, psci_disabled

     // check core data area to see if core cannot be turned on
     // read the core state
    mov  x0, x6
    mov  x1, #CORE_STATE_DATA
    bl   _getCoreData

    cmp  x0, #CORE_DISABLED
    b.eq psci_disabled
    cmp  x0, #CORE_PENDING
    b.eq psci_on_pending
    cmp  x0, #CORE_RELEASED
    b.eq psci_already_on
    mov  x9, x0

     // x4   = spsr_el3 of caller
     // x6   = core mask (lsb)
     // x7   = start address
     // x8   = context id
     // x9   = core state (from data area)

     // save spsr_el3 in data area
    mov  x0, x6
    mov  x1, #SPSR_EL3_DATA
    mov  x2, x4
    bl   _setCoreData

     // save scr_el3 in data area
    mov  x0, x6
    mov  x1, #SCR_EL3_DATA
    mrs   x2, scr_el3
    bl   _setCoreData

     // x6   = core mask (lsb)
     // x7   = start address
     // x8   = context id
     // x9   = core state (from data area)

     // set start addr in data area
    mov  x0, x6
    mov  x1, #START_ADDR_DATA
    mov  x2, x7
    bl   _setCoreData

     // set context id in data area
    mov  x0, x6
    mov  x1, #CNTXT_ID_DATA
    mov  x2, x8
    bl   _setCoreData

     // x6   = core mask (lsb)
     // x9   = core state (from data area)

    bl   _is_EL2_supported
    cbz  x0, 6f

     // core will be released to EL2

     // save sctlr_el2
    mov   x0, x6
    mov   x1, #SCTLR_DATA
    mrs   x2, sctlr_el2
    bl   _setCoreData

     // save hcr_el2    
    mov   x0, x6
    mov   x1, #HCR_EL2_DATA
    mrs   x2, hcr_el2
    bl   _setCoreData
    b    8f

6:   // core will be released to EL1

     // save sctlr_el1
    mov   x0, x6
    mov   x1, #SCTLR_DATA
    mrs   x2, sctlr_el1
    bl   _setCoreData

     // x6   = core mask (lsb)
     // x9   = core state (from data area)
8:
     // load the soc with the address for the secondary core to jump to
     // when it completes execution in the bootrom
    adr  x0, _secondary_core_init
    bl   _soc_set_start_addr

     // reread the state here
    mov  x0, x6
    mov  x1, #CORE_STATE_DATA
    bl   _getCoreData
    mov  x9, x0
    
     // x6   = core mask (lsb)
     // x9   = core state (from data area)

    cmp  x9, #CORE_IN_RESET
    b.eq core_in_reset
    cmp  x0, #CORE_OFF
    b.eq core_is_off
    cmp  x0, #CORE_OFF_PENDING
     // if state == CORE_OFF_PENDING, set abort
    mov  x0, x6
    mov  x1, #ABORT_FLAG_DATA
    mov  x2, #CORE_ABORT_OP
    bl   _setCoreData

    ldr  x3, =PSCI_ABORT_CNT
7:
     // watch for abort to take effect
    mov  x0, x6
    mov  x1, #CORE_STATE_DATA
    bl   _getCoreData
    cmp  x0, #CORE_OFF
    b.eq core_is_off
    cmp  x0, #CORE_PENDING
    b.eq psci_success

     // loop til finished
    sub  x3, x3, #1
    cbnz x3, 7b

     // if we didn't see either CORE_OFF or CORE_PENDING, then this
     // core is in CORE_OFF_PENDING - exit with success, as the core will
     // respond to the abort request
    b   psci_success

 // this is where we start up a core out of reset
core_in_reset:
     // see if the soc-specific module supports this op
    ldr  x7, =SOC_CORE_RELEASE
    cbz  x7, psci_unimplemented

     // x6   = core mask (lsb)

     // set core state in data area
    mov  x0, x6
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_PENDING
    bl   _setCoreData

     // release the core from reset and wait til it's up (or timeout)
    mov   x0, x6
    bl    _soc_core_rls_wait
    cbz   x0, psci_success
     // the core failed to come out of reset
    b     psci_failure

 // this is where we start up a core that has been powered-down via CPU_OFF
core_is_off:
     // see if the soc-specific module supports this op
    ldr  x7, =SOC_CORE_RESTART
    cbz  x7, psci_unimplemented

     // x6   = core mask (lsb)

     // set core state in data area
    mov  x0, x6
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_PENDING
    bl   _setCoreData

     // put the core back into service
    mov  x0, x6
    bl   _soc_core_restart    
    b    psci_success

//-----------------------------------------------------------------------------

smc64_psci_affinity_info:
     // x1 = target_affinity
     // x2 = lowest_affinity

     // save the LR
    mov  x12, x30

     // core affinity?
    mov   x0, #0
    cmp   x2, x0
    b.eq  affinity_info_0

     // cluster affinity?
    mov   x0, #1
    cmp   x2, x0
    b.eq  affinity_info_1

     // no other processing elements are present
    b   psci_not_present

affinity_info_0:
     // status of an individual core
     // x1 = target_affinity

    mov   x0, x1
    bl    _get_core_mask_lsb
    cbz   x0, psci_not_present

     // x0 = core mask

     // process cores here
    mov  x1, #CORE_STATE_DATA
    bl   _getCoreData

     // x0 = core state

     // ck for core disabled
    ldr   x1, =CORE_DISABLED
    cmp   x0, x1
    b.ne  1f
    b     psci_disabled

1:
     // ck for core pending
    ldr   x1, =CORE_PENDING
    cmp   x0, x1
    b.ne  2f
    b     affinity_lvl_pend

2:
     // ck for core on
    ldr   x1, =CORE_RELEASED
    cmp   x0, x1
    b.ne  3f
    b     affinity_lvl_on

3:
     // must be core off
    b     affinity_lvl_off

affinity_info_1:
     // status of a cluster
     // x1 = target_affinity

     // isolate and check the cluster number
    mov   x2, xzr
    bfxil x2, x1, #8, #8
    ldr   x3, =CLUSTER_COUNT
    cmp   x3, x2
    b.le  psci_not_present

     // x2 = cluster number

    bl    _get_cluster_state
    b     psci_success

//-----------------------------------------------------------------------------

smc32_psci_version:
     // save the LR
    mov  x12, x30

    ldr  x0, =PSCI_VERSION
    b    psci_completed

//-----------------------------------------------------------------------------

smc32_psci_cpu_off:
     // save link register initially in x12 
    mov  x12, x30

     // see if the soc-specific module supports this op
    ldr  x7, =SOC_CORE_OFF
    cbz  x7, psci_unimplemented

     // get EL level of core
     //  - err return if not EL1 or EL2
    mrs   x0, spsr_el3
    bl    _getCallerEL
    cbz   x0, psci_denied

     // check if this is the last core on
     // cpu_off cannot be used to power-down the final core
    bl   coreOnCount
    cmp  x0, #1
    b.eq psci_denied

    mrs  x0, MPIDR_EL1      
    bl   _get_core_mask_lsb 
    mov  x10, x0
    mov  x1, #CORE_STATE_DATA
    bl   _getCoreData

     // x0  = core state
     // x10 = core mask lsb

     // only cores in the ON, or the ON_PENDING state can be turned OFF
    cmp  x0, #CORE_ON_MIN
    b.lt psci_denied

     // there are no further error returns
     // x10 = core mask lsb

     // change state of core in data area
    mov  x0, x10
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_OFF_PENDING
    bl   _setCoreData

     // shutdown the core - phase 1
    mov  x0, x10 
    bl   _soc_core_phase1_off

     // x10 = core mask (lsb)

     //  check for abort flag - if the abort flag is set, that means
     // that while we are in the process of shutting this core down,
     // we have received a request to power it up - this can happen
     // becasue of the extreme latency to shut a core down
    mov  x0, x10
    mov  x1, #ABORT_FLAG_DATA
    bl   _getCoreData
    cbz  x0, 4f

     // process the abort
    mov  x0, x10
    bl   psci_processAbort
    b    2f

4:
     // x10 = core mask (lsb)
  
    // save link register in data area
    mov  x0, x10
    mov  x1, #LINK_REG_DATA
    mov  x2, x12
    bl   _setCoreData

     // x10 = core mask (lsb)

     // shutdown the core - phase 2
    mov  x0, x10
    bl   _soc_core_phase2_off

     // x10 = core mask (lsb) 

     //  check for abort flag - if the abort flag is set, that means
     // that while we are in the process of shutting this core down,
     // we have received a request to power it up - this can happen
     // because of the extreme latency to shut a core down
    mov  x0, x10
    mov  x1, #ABORT_FLAG_DATA
    bl   _getCoreData
    cbz  x0, 5f

     // process the abort
    mov  x0, x10
    bl   psci_processAbort
    b    3f

5:
     // shutdown the core
    mov  x0, x10
    bl   _soc_core_entr_off

     // start the core back up
    mov  x0, x10
    bl   _soc_core_exit_off

     // x10 = core mask (lsb)
3:
     // cleanup from phase2
    mov  x0, x10
    bl   _soc_core_phase2_clnup
2:
     // cleanup from phase1
    mov  x0, x10
    bl   _soc_core_phase1_clnup

     // xfer to the monitor
    b    _mon_core_restart

//-----------------------------------------------------------------------------

smc32_psci_system_off:
     // save link register
    mov  x12, x30

     // see if the soc-specific module supports this op
    ldr  x7, =SOC_SYSTEM_OFF
    cbz  x7, psci_unimplemented

//-----------------------------------------------------------------------------

smc32_psci_system_reset:
     // see if the soc-specific module supports this op
    ldr  x7, =SOC_SYSTEM_RESET
    cbz  x7, psci_unimplemented

     // save link register
    mov  x12, x30

     // system reset is soc-specific
    bl   _soc_sys_reset
    b    psci_completed

//-----------------------------------------------------------------------------

smc32_psci_features:
     // save link register
    mov  x12, x30

    b  psci_unimplemented

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// returns for affinity_info

affinity_lvl_on:
    mov  x0, #AFFINITY_LEVEL_ON
    b    psci_completed

     //------------------------------------------

affinity_lvl_off:
    mov  x0, #AFFINITY_LEVEL_OFF
    b    psci_completed

     //------------------------------------------

affinity_lvl_pend:
    mov  x0, #AFFINITY_LEVEL_PEND
    b    psci_completed

//-----------------------------------------------------------------------------
// psci std returns

psci_disabled:
    ldr  w0, =PSCI_DISABLED
    b    psci_completed

     //------------------------------------------

psci_not_present:
    ldr  w0, =PSCI_NOT_PRESENT
    b    psci_completed

     //------------------------------------------

psci_on_pending:
    ldr  w0, =PSCI_ON_PENDING
    b    psci_completed

     //------------------------------------------

psci_already_on:
    ldr  w0, =PSCI_ALREADY_ON
    b    psci_completed

     //------------------------------------------

psci_failure:
    ldr  w0, =PSCI_INTERNAL_FAILURE
    b    psci_completed

     //------------------------------------------

psci_unimplemented:
    ldr  w0, =PSCI_NOT_SUPPORTED
    b    psci_completed

     //------------------------------------------

psci_denied:
    ldr  w0, =PSCI_DENIED
    b    psci_completed

     //------------------------------------------

psci_invalid:
    ldr  w0, =PSCI_INVALID_PARMS
    b    psci_completed

     //------------------------------------------

psci_success:
    mov  x0, #PSCI_SUCCESS

psci_completed:
     // x0 = status code
    mov  x5, x0

     // called from aarch32 or aarch64?
    bl   _get_aarch_flag
    cbnz  x0, 1f

     // called from aarch64

     // restore the return code
    mov  x0, x5

     // restore the LR
    mov  x30, x12

     // zero-out the scratch registers
    ldr  x1, =REGISTER_OBFUSCATE
    mvn  x2,  x1
    mov  x3,  x1
    mov  x4,  x2
    mov  x5,  x1
    mov  x6,  x2
    mov  x7,  x1
    mov  x8,  x2
    mov  x9,  x1
    mov  x10, x2
    mov  x11, x1
    mov  x12, x2
    b    2f

1:   // called from aarch32
    mov  x0, x5

     // restore the aarch32 non-volatile registers
    bl   _restore_aarch32_nvolatile    

     // zero-out the scratch registers
    ldr  x1, =REGISTER_OBFUSCATE
    mvn  x2, x1
    mov  x3, x1
2:
     // return from exception
    eret

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

 // this function initializes the core data areas
 // only executed by the boot core
 // in:   none
 // out:  none
 // uses: x0, x1, x2, x3, x4, x5, x6
_initialize_psci:
    mov   x6, x30

    mov   x2, #CORE_RELEASED
    mov   x3, #1
    mov   x4, #CPU_MAX_COUNT
    adr   x5, _cpu0_data

1:
     // x2 = core state
     // x3 = core mask lsb
     // x4 = loop counter
     // x5 = core data area base address

    str   x2,  [x5, #CORE_STATE_DATA]
    str   xzr, [x5, #SPSR_EL3_DATA]
    str   xzr, [x5, #CNTXT_ID_DATA]
    str   xzr, [x5, #START_ADDR_DATA]
    str   xzr, [x5, #LINK_REG_DATA]
    str   xzr, [x5, #GICC_CTLR_DATA]
    str   xzr, [x5, #ABORT_FLAG_DATA]
    str   xzr, [x5, #SCTLR_DATA]
    str   xzr, [x5, #CPUECTLR_DATA]
    str   xzr, [x5, #AUX_01_DATA]
    str   xzr, [x5, #AUX_02_DATA]
    str   xzr, [x5, #AUX_03_DATA]
    str   xzr, [x5, #AUX_04_DATA]
    str   xzr, [x5, #AUX_05_DATA]
    str   xzr, [x5, #SCR_EL3_DATA]
    str   xzr, [x5, #HCR_EL2_DATA]

     // loop control
    sub  x4, x4, #1
    cbz  x4, 3f

     // increment to next data area
    add  x5, x5, #CORE_DATA_OFFSET
     // generate next core mask
    lsl  x3, x3, #1

     // set core state in x2
    mov  x0, x3
    bl   _soc_ck_disabled
    mov  x2, #CORE_IN_RESET
    cbz  x0, 1b
    mov  x2, #CORE_DISABLED
    b    1b

3:
    mov   x30, x6
    ret

//-----------------------------------------------------------------------------

 // this function stores the sctlr_elx value of the calling entity
 // in:   w0 = core mask (lsb)
 //       w1 = SPSR EL-level (must be one of: SPSR_EL1, SPSR_EL2)
 // uses: x0, x1, x2, x3, x4
save_core_sctlr:
    mov   x4, x30

     // x0 = core mask lsb

    cmp   w1, #SPSR_EL1
    b.eq  1f
    mrs   x2, sctlr_el2
    b     2f
1:
    mrs   x2, sctlr_el1
2:

     // x0 = core mask lsb
     // x2 = sctlr value to save

    mov  x1, #SCTLR_DATA
    bl   _setCoreData

    mov   x30, x4 
    ret

//-----------------------------------------------------------------------------

 // this function processes a request to abort CPU_OFF - an abort request can
 // occur if we are processing CPU_OFF, and a CPU_ON is issued for the same core
 // in:   w0 = core mask (lsb)
 // out:  none
 // uses: x0, x1, x2, x3, x4, x5
psci_processAbort:
    mov  x5, x30

     // x0 = core mask lsb

     // clear the abort flag
    mov   x4, x0
    mov   x1, #ABORT_FLAG_DATA
    mov   x2, xzr
    bl    _setCoreData

     // set the core state to CORE_PENDING
    mov   x0, x4
    mov   x1, #CORE_STATE_DATA
    mov   x2, #CORE_PENDING
    bl    _setCoreData

    mov   x30, x5 
    ret

//-----------------------------------------------------------------------------

 // this function locates a core that is available to perform an
 // initialization task
 // in:  none
 // out: x0 = 0, no available core
 //      x0 = core mask lsb of available core
 // uses x0, x1, x2, x3, x4
_find_core:

    mov   x4, x30

     // start the search at core 1
    mov   x3, #2
3:
     // see if core is disabled
    mov   x0, x3
    bl    _soc_ck_disabled
    cbnz  x0, 1f

     // x3 = core mask lsb

     // get the state of the core
    mov   x0, x3
    mov   x1, #CORE_STATE_DATA
    bl    _getCoreData
     
     // x0 = core state

     // see if core is in reset - this is the state we want
    mov   x1, #CORE_IN_RESET
    cmp   x0, x1
    mov   x0, x3
    b.eq  2f 
1:
    cmp   x3, #CORE_MASK_MAX
    mov   x0, xzr
    b.eq  2f

    lsl   x3, x3, #1
    b     3b
2:
    mov   x30, x4
    ret

//-----------------------------------------------------------------------------

 // this function returns the number of cores that are ON in the LS2080, based on
 // the core state read from each core's data area. The current core will be counted
 // as 'ON' if its data area indicates so
 // in:   none
 // out:  x0 = number of cores that are ON
 // uses: x0, x1, x2, x3, x4, x5
coreOnCount:
    mov x5, x30
   
    ldr x4, =CPU_MAX_COUNT 
    mov x2, xzr
    mov x3, #1

     // x2 = number of cores on
     // x3 = core mask lsb
     // x4 = loop count
1:  
    mov  x0, x3
    mov  x1, #CORE_STATE_DATA
    bl   _getCoreData

     // x0 = core state

     // if core state <= CORE_OFF_MAX, core is OFF
    cmp  x0, #CORE_OFF_MAX
    b.ls 2f
     // core is not OFF, so increment count                  
    add  x2, x2, #1

2:  
     // decrement loop counter
    sub  x4, x4, #1
    cbz  x4, 3f
     // shift mask bit to select next core
    lsl  x3, x3, #1
    b    1b

3:
     // put result in R0, and restore link register
    mov  x0, x2     
    mov  x30, x5     
    ret

//-----------------------------------------------------------------------------

 // this function returns the number of active cores in the system
 // in:  none
 // out: x0 = count of cores running
 // uses x0, x1, x2, x3, x4, x5, x6
core_on_cnt_sys:
    mov  x6, x30
    ldr  x3, =CPU_MAX_COUNT
    mov  x4, #1
    mov  x5, xzr

     // x3 = loop count
     // x4 = core mask lsb
     // x5 = accumulated count of running cores
     // x6 = saved link reg

3:
    mov  x0, x4
    mov  x1, #CORE_STATE_DATA
    bl   _getCoreData

     // x0 = core state

    cmp  x0, #CORE_OFF_MAX
    b.le 1f
    add  x5, x5, #1
1:
     // decrement the loop count and exit if finished
    sub  x3, x3, #1
    cbz  x3, 2f

     // increment to the next core
    lsl  x4, x4, #1
    b    3b
2:
     // xfer the count to the output reg
    mov  x0, x5
    mov  x30, x6
    ret

 //----------------------------------------------------------------------------

 // include the data areas
#include "psci_data.h"

.align 4
save_gicd_ctlr:
    .4byte  0x0

     // the reservation granule, as read from the CTL_EL0 register, is 16-words
     // we need to reserve this much space to insure that there are no unexpected
     // accesses that will disturb the exclusive-access methodology
//.align 4
//lock_01:
//    .4byte  0x0  // lock at word 0
//    .4byte  0x0  // reserved for reservation granule word 01
//    .4byte  0x0  // reserved for reservation granule word 02
//    .4byte  0x0  // reserved for reservation granule word 03
//    .4byte  0x0  // reserved for reservation granule word 04
//    .4byte  0x0  // reserved for reservation granule word 05
//    .4byte  0x0  // reserved for reservation granule word 06
//    .4byte  0x0  // reserved for reservation granule word 07
//    .4byte  0x0  // reserved for reservation granule word 08
//    .4byte  0x0  // reserved for reservation granule word 09
//    .4byte  0x0  // reserved for reservation granule word 0A
//    .4byte  0x0  // reserved for reservation granule word 0B
//    .4byte  0x0  // reserved for reservation granule word 0C
//    .4byte  0x0  // reserved for reservation granule word 0D
//    .4byte  0x0  // reserved for reservation granule word 0E
//    .4byte  0x0  // reserved for reservation granule word 0F

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

