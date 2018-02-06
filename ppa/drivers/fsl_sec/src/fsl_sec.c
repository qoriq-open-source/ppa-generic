//-----------------------------------------------------------------------------
// 
// Copyright 2017 NXP Semiconductors
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
// Authors:
//  Ruchika Gupta <ruchika.gupta@nxp.com> 
//
//-----------------------------------------------------------------------------

#include "types.h"
#include "fsl_sec.h"
#include "sec_jr_driver.h"
#include "sec_hw_specific.h"
#include "jobdesc.h"
#include "lib.h"
#include "io.h"

 // Job ring 3 is reserved for usage by sec firmware
#define DEFAULT_JR	3
static void *job_ring;

 // This function sets the TZ bit for the Job ring number passed as @num
static void config_tz(int num)
{
    uint32_t jricid;

     // Setting TZ bit of job ring
    switch(num) {
	case 0:
            jricid = sec_in32(CAAM_BASE_ADDR + SEC_REG_JR0ICIDR_MS_OFFSET);
	    sec_out32(CAAM_BASE_ADDR + SEC_REG_JR0ICIDR_MS_OFFSET, 
		      jricid | JRICID_MS_TZ);
	    break;
	case 1:
            jricid = sec_in32(CAAM_BASE_ADDR + SEC_REG_JR1ICIDR_MS_OFFSET);
	    sec_out32(CAAM_BASE_ADDR + SEC_REG_JR1ICIDR_MS_OFFSET, 
		      jricid | JRICID_MS_TZ);
	    break;
	case 2:
            jricid = sec_in32(CAAM_BASE_ADDR + SEC_REG_JR2ICIDR_MS_OFFSET);
	    sec_out32(CAAM_BASE_ADDR + SEC_REG_JR2ICIDR_MS_OFFSET, 
		      jricid | JRICID_MS_TZ);
	    break;
	case 3:
            jricid = sec_in32(CAAM_BASE_ADDR + SEC_REG_JR3ICIDR_MS_OFFSET);
	    sec_out32(CAAM_BASE_ADDR + SEC_REG_JR3ICIDR_MS_OFFSET, 
		      jricid | JRICID_MS_TZ);
	    break;
	default:
	    break;
    }
}

 // This function checks if Virtualization is enabled for JR and
 // accordingly sets the bot for starting JR<num> in JRSTARTR register
static inline void start_jr(int num)
{
    uint32_t ctpr = sec_in32((CAAM_BASE_ADDR + SEC_REG_CTPR_MS_OFFSET));
    uint32_t tmp = sec_in32((CAAM_BASE_ADDR + SEC_REG_JRSTARTR_OFFSET));
    uint32_t scfgr = sec_in32((CAAM_BASE_ADDR + SEC_REG_SCFGR_OFFSET));
    bool start = false;
	
    if (ctpr & CTPR_VIRT_EN_INC) {
	if ((ctpr & CTPR_VIRT_EN_POR) || (scfgr & SCFGR_VIRT_EN)) {
	    start = true;
	}
    } else {
	if (ctpr & CTPR_VIRT_EN_POR) {
	    start = true;
	}
    }

    if (start == true) {
        switch(num) {
	case 0:
	    tmp |= JRSTARTR_STARTJR0;
	    break;
	case 1:
	    tmp |= JRSTARTR_STARTJR1;
	    break;
	case 2:
	    tmp |= JRSTARTR_STARTJR2;
	    break;
	case 3:
	    tmp |= JRSTARTR_STARTJR3;
	    break;
	default:
	    break;
        }
    }
    sec_out32((CAAM_BASE_ADDR + SEC_REG_JRSTARTR_OFFSET), tmp);  
}

 // This functions configures the Job Ring
 // JR3 is reserved for use by Secure world
static int configure_jr(int num)
{
    int ret;
    void *reg_base_addr;

    switch(num) {
	case 0:
	    reg_base_addr = (void *)(CAAM_BASE_ADDR + CAAM_JR0_OFFSET);
	    break;
	case 1:
	    reg_base_addr = (void *)(CAAM_BASE_ADDR + CAAM_JR1_OFFSET);
	    break;
	case 2:
	    reg_base_addr = (void *)(CAAM_BASE_ADDR + CAAM_JR2_OFFSET);
	    break;
	case 3:
	    reg_base_addr = (void *)(CAAM_BASE_ADDR + CAAM_JR3_OFFSET);
	    break;
	default:
	    break;
    }

     // Initialize the JR library
    ret = sec_jr_lib_init();
    if (ret != 0) {
        debug("Error in sec_jr_lib_init");
        return -1;
    }

    start_jr(num);

     // Do HW configuration of the JR
    job_ring = init_job_ring(SEC_NOTIFICATION_TYPE_POLL, 0, 0,
			     reg_base_addr, 0);

    if (!job_ring) {
        debug("Error in init_job_ring");
        return -1;
    }
    
    return ret;
}

 // This function configures and locks the ICID values for various JR
 // TBD
static inline void configure_icid(void)
{
	return;
}

 // This function configures the TZ settings of RTIC
 // TBD
static inline void configure_rtic(void)
{
	return;
}

 // This function initializes SEC block, does basic parameter setting
 // configures the default Job ring assigned to TZ /secure world
 // Instantiates the RNG
int sec_init(void)
{
    int ret;
    uint32_t mcfgr = sec_in32(CAAM_BASE_ADDR + SEC_REG_MCFGR_OFFSET);

     // Modify CAAM Read/Write attributes
     // AXI Write - Cacheable, WB and WA
     // AXI Read - Cacheable, RA
#if defined(CONFIG_ARCH_LS2080A) || defined(CONFIG_ARCH_LS2088A)
    mcfgr = (mcfgr & ~MCFGR_AWCACHE_MASK) | (0xb << MCFGR_AWCACHE_SHIFT);
    mcfgr = (mcfgr & ~MCFGR_ARCACHE_MASK) | (0x6 << MCFGR_ARCACHE_SHIFT);
#else
    mcfgr = (mcfgr & ~MCFGR_AWCACHE_MASK) | (0x2 << MCFGR_AWCACHE_SHIFT);
#endif

     // Set PS bit to 1
#ifdef CONFIG_PHYS_64BIT
    mcfgr |= (1 << MCFGR_PS_SHIFT);
#endif
    sec_out32(CAAM_BASE_ADDR + SEC_REG_MCFGR_OFFSET, mcfgr);

    debug_hex("MCFGR", mcfgr);
     // Asssign ICID to all Job rings and lock tehm for usage
    configure_icid();

     // Configure the RTIC
    configure_rtic();

     // Configure the default JR for usage
    ret = configure_jr(DEFAULT_JR);
    if (ret != 0) {
        debug("\nFSL_JR: configuraiton failure\n");
        return -1;
    }

     // Do TZ configuration of default JR for sec firmware
    config_tz(DEFAULT_JR);

    // Instantiate the RNG
    ret = hw_rng_instantiate();
    if (ret != 0) {
        debug("\nRNG Instantiation failure\n");
        return -1;
    }

    return ret;
}

 // This function is used for sumbitting job to the Job Ring
 // [param] [in] - jobdesc to be submitted
 // Return - -1 in case of error and 0 in case of SUCCESS
int run_descriptor_jr(struct job_descriptor *jobdesc)
{
    int i = 0, ret = 0;
    uint32_t *desc_addr = jobdesc->desc;
    uint32_t desc_len = desc_length(jobdesc->desc);
    uint32_t desc_word;

    for (i = 0; i < desc_len; i++) {
        desc_word = desc_addr[i];
        sec_out32((uint32_t *)&desc_addr[i], desc_word);
    }

    for (i = 0; i < desc_len; i++)
	debug_hex("", desc_addr[i]);

    ret = enq_jr_desc(job_ring, jobdesc);
    if (ret == 0) {
        debug("JR enqueue done...");
    } else {
        debug("Error in Enqueue");
	return ret;
    }

    debug("Dequeue in progress");

    ret = dequeue_jr(job_ring, -1); 
    if (ret > 0) {
	debug_hex("Dequeue of %d desc success", ret);
        ret = 0;
    } else {
        debug_hex("deq_ret", ret); 
	ret = -1;
    }
	
    return ret;
}

 // this function returns a random number using HW RNG Algo
 // In case of failure, random number returned is 0
 // prngWidth = 0 - 32 bit random number
 // prngWidth > 0 means 64 bit random number
unsigned long long _get_RNG(int rngWidth)
{
    unsigned long long result;
    static uint8_t *rand_byte ;
    uint8_t rand_byte_swp[8];
    int bytes = 0;
    int i = 0;
    int ret = 0;

#ifdef TEST
    rand_byte[0] = 0x12;
    rand_byte[1] = 0x34;
    rand_byte[2] = 0x56;
    rand_byte[3] = 0x78;
    rand_byte[4] = 0x9a;
    rand_byte[5] = 0xbc;
    rand_byte[6] = 0xde;
    rand_byte[7] = 0xf1;
#endif

    if (rngWidth == 0)
        bytes = 4;
    else
        bytes = 8;

     // TBD - Current allocator doesn't have a free function
     // Remove static once free implementation is available
    if (!rand_byte) {
	rand_byte = alloc(64, 64);
	if (!rand_byte) {
	    debug("Allocation for Buffer for random bytes failed\n");
	    ret = 1;
	    goto out;
	}
    }

    memset(rand_byte, 64, 0);

    ret = get_rand_bytes_hw(rand_byte, bytes);

out:
    for (i = 0; i < bytes; i++) {
	if (ret) {
	     // Return 0 in case of failure
            rand_byte_swp[i] = 0;
	} else {
            rand_byte_swp[i] = rand_byte[bytes - i - 1];
        }
    }

    result = *(unsigned long long *)&rand_byte_swp[0];

    debug_hex("result", result);

    return result;

}  // _get_RNG()

unsigned int _get_hw_unq_key(unsigned char *hw_key, unsigned int size)
{
	int ret = 0;
	ret = get_hw_unq_key_blob_hw(hw_key, size);
	if(ret)
		memset(hw_key, 0xad, size);
	return ret;
}
