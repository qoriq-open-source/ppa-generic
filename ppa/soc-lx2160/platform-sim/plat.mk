#------------------------------------------------------------------------------
# 
# Copyright 2017 NXP Semiconductors
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Author Rod Dorris <rod.dorris@nxp.com>
# 
#------------------------------------------------------------------------------
#
# sim platform specific definitions
#
# supported targets:
#   sim - binary image linked with bootrom code
#
# -----------------------------------------------------------------------------
#
# builds a ppa bound in with the bootrom code, suitable for execution on any target which
# does not contain bootrom (simulator, emulator)
sim:
	$(MAKE) SIM_BUILD=1 sim_out
	$(MAKE) SIM_BUILD=1 sim_bin
sim_out:
	@echo 'build: image=sim \ $(GIC_FILE) \ $(INTER_FILE) \ ddr $(DDR):$(PLAT) \ debug $(DBG) \ test "$(TEST)"'
	@echo
sim_bin: bootmain.64.elf.rom.rmh0.rmh

# -----------------------------------------------------------------------------

# add psci-related source and headers here
SRC_PSCI   =psci.s
HDRS_PSCI  =psci.h psci_data.h

# add soc-specific source and headers here
SRC_SOC    =bootmain.64.s nonboot64.s soc.s
HDRS_SOC   =soc.h soc.mac boot.h

# add arm-specific source and headers here
SRC_ARMV8  =aarch64.s $(INTER_FILE).s $(GIC_FILE).s
HDRS_ARMV8 =aarch64.h

# add security-monitor source and headers here
SRC_MNTR   =monitor.s smc64.s smc32.s vector.s
HDRS_MNTR  =smc.h

 # add platform-specific asm sources here
PLAT_ASM =

# add platform-specific C source and headers here
SRC_PLAT   =
HDRS_PLAT  =config.h policy.h

 # add platform-test-specific asm sources here
TEST_ASM =$(TEST_FILE)

ifeq ($(DDR_BLD), 1)
  # add soc-specific C source and headers here
  CSRC_SOC   =errata.c
  CHDRS_SOC  =

  # add ddr-specific source and headers here
  DDR_C    =ddr_init.c
  DDR_HDRS =plat.h

  # add sources for the ddr, i2c, and uart drivers here
  DRIVER_C = utility.c regs.c ddr.c ddrc.c dimm.c opts.c debug.c crc32.c spd.c \
	addr.c uart.c i2c.c timer.c
  DRIVER_HDRS = utility.h lsch3.h immap.h ddr.h dimm.h opts.h regs.h debug.h \
	errno.h io.h i2c.h lib.h timer.h uart.h
else
  CSRC_SOC    =
  CHDRS_SOC   =
  DDR_C       =
  DDR_HDRS    =
  DRIVER_C    =
  DRIVER_HDRS =
endif

# -----------------------------------------------------------------------------

bootmain.64.elf.rom.rmh0.rmh: bootmain.64.elf bootmain.64.bin
	perl $(CMMN_SRC)/elf-to-rmh.prl -f $(OBJ_DIR)/bootmain.64.elf > $(OBJ_DIR)/log.txt

# -----------------------------------------------------------------------------
