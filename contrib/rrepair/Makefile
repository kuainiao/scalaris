SHELL := /bin/bash
MAKEFLAGS=-k $MAKEFLAGS
SUBDIRS := $(shell ls -d */ 2>/dev/null)
SUBDIRS_DIR := $(patsubst %/,%-dir,$(SUBDIRS))
SUBDIRS_DIR_CLEAN := $(patsubst %/,%-dir-clean,$(SUBDIRS))
SYSTEM_SIZE=100000
SYSTEM_SIZE_SCALE=4000
EVAL_REPEATS ?= 100

.PHONY: all clean subdirs
.PRECIOUS: %/.gitignore %/Makefile

all: subdirs

clean: $(SUBDIRS_DIR_CLEAN)

subdirs: $(SUBDIRS_DIR)

# % replaces any name
# within a rule: $@ inserts the target
#                $< inserts the first dependency (source)
#                $+ inserts a list of all dependencies
#                $^ inserts a list of all unique dependencies
#                $* inserts the stem an implicit rule matches with
%-dir:
	$(MAKE) -C "$*"

%-dir-clean:
	$(MAKE) clean -C "$*"

scalaris:
	$(MAKE) -C ../..

%/.gitignore: gitignore.tmpl2
	@mkdir -p "$(@D)"
	@cp gitignore.tmpl2 $@

EXP_DELTA_LIST=$(shell LC_NUMERIC=C seq -s" " 0.1 0.1 1 ; seq -s" " 0 1 9 ; seq -s" " 10 10 100) as_fprob
# keep ALL_P in sync with the special makefile targets creating the summary plots!
ALL_P=0.1 0.01 0.001 0.0001

define FPROB_MAKEFILE
$(1)_0-%_expD$(2)-all/Makefile: Makefile.tmpl2 $(1)_0-%_expD$(2)-all/.gitignore Makefile
	@mkdir -p "$$(@D)"
	@sed -e 's|<sys_size>|$(SYSTEM_SIZE)|g' \
         -e 's|<dat1>|0.1/$(1).dat|g' \
         -e 's|<dat2>|0.01/$(1).dat|g' \
         -e 's|<dat3>|0.001/$(1).dat|g' \
         -e 's|<dat4>|0.0001/$(1).dat|g' \
         -e 's|<dat5>||g' \
         -e 's|<title1>|$(1)_{P_{1e}0.1}|g' \
         -e 's|<title2>|$(1)_{P_{1e}0.01}|g' \
         -e 's|<title3>|$(1)_{P_{1e}0.001}|g' \
         -e 's|<title4>|$(1)_{P_{1e}0.0001}|g' \
         -e 's|<title5>||g' \
         -e 's|<morecommands>|absoluteRedundancy=1;stepSize=0$$(shell bc <<< "scale=2; $$*/5");|g' < $$< > $$@
endef
$(foreach ALG, trivial shash bloom, $(foreach EXP_DELTA, $(EXP_DELTA_LIST),\
$(eval $(call FPROB_MAKEFILE,$(ALG),$(EXP_DELTA),$(VARIANT)))\
))

# fprob analysis (different delta) for different recon parameters
define MAX_DELTA_TARGETS
.PRECIOUS: $(1)_0-$(2)_expD$(3)-all/Makefile
$(1)_0-$(2)_expD$(3)-all/%/$(1).dat: $(1)_0-$(2)_expD$(3)-all/Makefile
	@echo " executing $$(@D) (N=$(SYSTEM_SIZE))"
	@mkdir -p "$$(@D)"
	+STEP_SIZE=0$$(shell bc <<< "scale=2; $(2)/5") ; ./rr_eval.sh -a $(1) -n "$(SYSTEM_SIZE)" -c "$$*,$(3),$$$$STEP_SIZE" -g eval_fprob.gp -t "$(1)_{P_{1e}$$*}" -d "$$(@D)" -r $(EVAL_REPEATS) -s $$$$STEP_SIZE > "$$(@D)/eval.log"
endef
$(foreach ALG, trivial shash bloom, $(foreach MAX_DELTA, 1 10 100, $(foreach EXP_DELTA, $(EXP_DELTA_LIST),\
$(eval $(call MAX_DELTA_TARGETS,$(ALG),$(MAX_DELTA),$(EXP_DELTA)))\
)))

define OTHER_TARGETS
# ddist+fdist analysis (different data and failure distributions) for different recon parameters
.PRECIOUS: $(1)_ddists_fdists_expD$(2)-all/Makefile
$(1)_ddists_fdists_expD$(2)-all/%/$(1)_ddists_fdists.dat: $(1)_ddists_fdists_expD$(2)-all/Makefile
	@echo " executing $$(@D) (N=$(SYSTEM_SIZE))"
	@mkdir -p "$$(@D)"
	+STEP_SIZE=2 ; ./rr_eval.sh -a $(1)_ddists_fdists -n "$(SYSTEM_SIZE)" -c "$$*,$(2),$$$$STEP_SIZE" -g eval_fprob_dists.gp -t "$(1)_{P_{1e}$$*}" -d "$$(@D)" -r $(EVAL_REPEATS) -s $$$$STEP_SIZE > "$$(@D)/eval.log"

# scalability analysis (increasing data size) for different recon parameters
.PRECIOUS: $(1)_scale_expD$(2)-all/Makefile
$(1)_scale_expD$(2)-all/Makefile: Makefile_scale.tmpl2 $(1)_scale_expD$(2)-all/.gitignore Makefile
	@mkdir -p "$$(@D)"
	@sed -e 's|<sys_size>|$(SYSTEM_SIZE_SCALE)|g' \
         -e 's|<dat1>|0.1/$(1)_scale.dat|g' \
         -e 's|<dat2>|0.01/$(1)_scale.dat|g' \
         -e 's|<dat3>|0.001/$(1)_scale.dat|g' \
         -e 's|<dat4>|0.0001/$(1)_scale.dat|g' \
         -e 's|<dat5>||g' \
         -e 's|<title1>|$(1)_{P_{1e}0.1}|g' \
         -e 's|<title2>|$(1)_{P_{1e}0.01}|g' \
         -e 's|<title3>|$(1)_{P_{1e}0.001}|g' \
         -e 's|<title4>|$(1)_{P_{1e}0.0001}|g' \
         -e 's|<title5>||g' \
         -e 's|<morecommands>|absoluteRedundancy=1;|g' < $$< > $$@

$(1)_scale_expD$(2)-all/%/$(1)_scale.dat: $(1)_scale_expD$(2)-all/Makefile
	@echo " executing $$(@D) (start at N=$(SYSTEM_SIZE_SCALE))"
	@mkdir -p "$$(@D)"
	+./rr_eval.sh -a $(1)_scale -n "$(SYSTEM_SIZE_SCALE)" -c "$$*,$(2)" -g eval_data_inc.gp -t "$(1)_{P_{1e}$$*}" -d "$$(@D)" -r $(EVAL_REPEATS) > "$$(@D)/eval.log"
endef
$(foreach ALG, trivial shash bloom, $(foreach EXP_DELTA, as_fprob,\
$(eval $(call OTHER_TARGETS,$(ALG),$(EXP_DELTA)))\
))

# define summary targets for groups of the ones above:
define SUM_1
# fprob analysis (different delta)
$(1)_0-$(2)-all: $(foreach P1E, $(ALL_P), $(1)_0-$(2)-all/$(P1E)/$(1).dat)
	
endef
$(foreach ALG, trivial shash bloom, $(foreach PAR, 1_expDas_fprob 10_expDas_fprob 100_expDas_fprob 1_expD1 10_expD1 100_expD1,\
$(eval $(call SUM_1,$(ALG),$(PAR)))\
))

define SUM_2
# fprob analysis (different delta)
$(1)-all: $(foreach PAR, 0-1_expDas_fprob 0-10_expDas_fprob 0-100_expDas_fprob 0-10_expD1 0-100_expD1, $(1)_$(PAR)-all)
	
endef
$(foreach ALG, trivial shash bloom, $(eval $(call SUM_2,$(ALG))))

define SUM_3
# ddist+fdist analysis (different data and failure distributions)
$(1)_dists-all: $(1)_ddists_fdists_expDas_fprob-all/0.01/$(1)_ddists_fdists.dat
	
# scalability analysis (increasing data size)
$(1)_scale-all: $(foreach P1E, $(ALL_P), $(1)_scale_expDas_fprob-all/$(P1E)/$(1)_scale.dat)
	
$(1): $(1)-all $(1)_dists-all $(1)_scale-all
	
endef
$(foreach ALG, trivial shash bloom, $(eval $(call SUM_3,$(ALG))))

# v4_b3_p0.001
MERKLE_EXTRACT_V='v\([0-9][0-9]*\)_b[0-9][0-9]*_p[0-9][.0-9]*'
MERKLE_EXTRACT_B='v[0-9][0-9]*_b\([0-9][0-9]*\)_p[0-9][.0-9]*'
MERKLE_EXTRACT_P='v[0-9][0-9]*_b[0-9][0-9]*_p\([0-9][.0-9]*\)'

define MERKLE_FPROB_TARGETS
# fprob analysis (different delta) for different merkle recon parameters
.PRECIOUS: merkle_0-$(1)_expD$(2)-all/Makefile
merkle_0-$(1)_expD$(2)-all/%/merkle.dat: merkle_0-$(1)_expD$(2)-all/Makefile
	@echo " executing $$(@D) (N=$(SYSTEM_SIZE))"
	@mkdir -p "$$(@D)"
	+V=$$(shell expr match "$$*" $(MERKLE_EXTRACT_V)) ; B=$$(shell expr match "$$*" $(MERKLE_EXTRACT_B)) ; P=$$(shell expr match "$$*" $(MERKLE_EXTRACT_P)); STEP_SIZE=0$$(shell bc <<< "scale=2; $(1)/5") ; ./rr_eval.sh -a merkle -n "$(SYSTEM_SIZE)" -c "$$$${V},$$$${B},$$$${P},$(2),$$$$STEP_SIZE" -g eval_fprob.gp -t "merkle_{v$$$${V}, b$$$${B}, P_{1e}$$$${P}}" -d "$$(@D)" -r $(EVAL_REPEATS) -s $$$$STEP_SIZE > "$$(@D)/eval.log"
endef
$(foreach MAX_DELTA, 1 10 100, $(foreach EXP_DELTA, $(EXP_DELTA_LIST),\
$(eval $(call MERKLE_FPROB_TARGETS,$(MAX_DELTA),$(EXP_DELTA)))\
))

define MERKLE_OTHER_TARGETS
# ddist+fdist analysis (different data and failure distributions) for different recon parameters
.PRECIOUS: merkle_ddists_fdists_expD$(1)-all/Makefile
merkle_ddists_fdists_expD$(1)-all/%/merkle_ddists_fdists.dat: merkle_ddists_fdists_expD$(1)-all/Makefile
	@echo " executing $$(@D) (N=$(SYSTEM_SIZE))"
	@mkdir -p "$$(@D)"
	+STEP_SIZE=2 ; V=$$(shell expr match "$$*" $(MERKLE_EXTRACT_V)) ; B=$$(shell expr match "$$*" $(MERKLE_EXTRACT_B)) ; P=$$(shell expr match "$$*" $(MERKLE_EXTRACT_P)) ; ./rr_eval.sh -a merkle_ddists_fdists -n "$(SYSTEM_SIZE)" -c "$$$${V},$$$${B},$$$${P},$(1),$$$$STEP_SIZE" -g eval_fprob_dists.gp -t "merkle_{v$$$${V}, b$$$${B}, P_{1e}$$$${P}}" -d "$$(@D)" -r $(EVAL_REPEATS) -s $$$$STEP_SIZE > "$$(@D)/eval.log"

# scalability analysis (increasing data size) for different recon parameters
.PRECIOUS: merkle_scale_expD$(1)-all/Makefile
merkle_scale_expD$(1)-all/%/merkle_scale.dat: merkle_scale_expD$(1)-all/Makefile
	@echo " executing  $$(@D) (start at N=$(SYSTEM_SIZE_SCALE))"
	@mkdir -p "$$(@D)"
	+V=$$(shell expr match "$$*" $(MERKLE_EXTRACT_V)) ; B=$$(shell expr match "$$*" $(MERKLE_EXTRACT_B)) ; P=$$(shell expr match "$$*" $(MERKLE_EXTRACT_P)) ; ./rr_eval.sh -a merkle_scale -n "$(SYSTEM_SIZE_SCALE)" -c "$$$${V},$$$${B},$$$${P},$(1)" -g eval_data_inc.gp -t "merkle_{v$$$${V}, b$$$${B}, P_{1e}$$$${P}}" -d "$$(@D)" -r $(EVAL_REPEATS) > "$$(@D)/eval.log"
endef
$(foreach EXP_DELTA, as_fprob,\
$(eval $(call MERKLE_OTHER_TARGETS,$(EXP_DELTA)))\
)

MERKLE_DEFAULT_V_B=v4_b2
MERKLE_DEFAULT_B_P=b2_p0.01
MERKLE_DEFAULT_V_P=v4_p0.01
ALL_V=2 3 4 8 16
ALL_B=1 2 3 4 8

# define summary targets for groups of the ones above:
define MERKLE_SUM_1
# fprob analysis (different delta)
merkle_0-$(1)-all: $(foreach PAR, $(MERKLE_DEFAULT_V_B), merkle_0-$(1)-all/$(PAR)) $(foreach PAR, $(MERKLE_DEFAULT_B_P), merkle_0-$(1)-all/$(PAR)) $(foreach PAR, $(MERKLE_DEFAULT_V_P), merkle_0-$(1)-all/$(PAR))
	
endef
$(foreach PAR, 1_expDas_fprob 10_expDas_fprob 100_expDas_fprob 1_expD1 10_expD1 100_expD1,$(eval $(call MERKLE_SUM_1,$(PAR))))

merkle-all: $(foreach PAR, 0-1_expDas_fprob 0-10_expDas_fprob 0-100_expDas_fprob 0-10_expD1 0-100_expD1, merkle_$(PAR)-all)
	

# ddist+fdist analysis (different data and failure distributions)
merkle_dists-all: $(foreach PAR, $(MERKLE_DEFAULT_V_B), merkle_ddists_fdists_expDas_fprob-all/$(PAR)_p0.01/merkle_ddists_fdists.dat)
	

# scalability analysis (increasing data size)
merkle_scale-all: $(foreach PAR, $(MERKLE_DEFAULT_V_B), merkle_scale_expDas_fprob-all/$(PAR)) $(foreach PAR, $(MERKLE_DEFAULT_B_P), merkle_scale_expDas_fprob-all/$(PAR)) $(foreach PAR, $(MERKLE_DEFAULT_V_P), merkle_scale_expDas_fprob-all/$(PAR))
	

# summary targets for v4_b3 b1_p0.01 v4_p0.01 (Makefiles and dependencies)
define MERKLE_SUM_V_B
merkle_0-$(1)_expD$(2)-all/$(3)/Makefile: Makefile.tmpl2 merkle_0-$(1)_expD$(2)-all/$(3)/.gitignore Makefile
	@mkdir -p "$$(@D)"
	@V=$$(shell expr match "$(3)" 'v\([0-9][0-9]*\)_b[0-9][0-9]*') ; B=$$(shell expr match "$(3)" 'v[0-9][0-9]*_b\([0-9][0-9]*\)') ; \
      sed -e 's|<sys_size>|$(SYSTEM_SIZE)|g' \
          -e "s|<dat1>|../v$$$${V}_b$$$${B}_p0.1/merkle.dat|g" \
          -e "s|<dat2>|../v$$$${V}_b$$$${B}_p0.01/merkle.dat|g" \
          -e "s|<dat3>|../v$$$${V}_b$$$${B}_p0.001/merkle.dat|g" \
          -e "s|<dat4>|../v$$$${V}_b$$$${B}_p0.0001/merkle.dat|g" \
          -e 's|<dat5>||g' \
          -e "s|<title1>|merkle_{v$$$${V}, b$$$${B}, P_{1e}0.1}|g" \
          -e "s|<title2>|merkle_{v$$$${V}, b$$$${B}, P_{1e}0.01}|g" \
          -e "s|<title3>|merkle_{v$$$${V}, b$$$${B}, P_{1e}0.001}|g" \
          -e "s|<title4>|merkle_{v$$$${V}, b$$$${B}, P_{1e}0.0001}|g" \
          -e 's|<title5>||g' \
          -e 's|<morecommands>|absoluteRedundancy=1;stepSize=0$$(shell bc <<< "scale=2; $(1)/5");|g' \
          -e 's|../eval_fprob.gp|../../eval_fprob.gp|g' \
          -e 's|../coldefs_eval_point.gp|../../coldefs_eval_point.gp|g' < $$< > $$@

merkle_0-$(1)_expD$(2)-all/$(3): merkle_0-$(1)_expD$(2)-all/$(3)/Makefile $(foreach P1E, $(ALL_P), merkle_0-$(1)_expD$(2)-all/$(3)_p$(P1E)/merkle.dat)
	
endef
$(foreach MAX_DELTA, 1 10 100, $(foreach EXP_DELTA, $(EXP_DELTA_LIST), $(foreach V, $(ALL_V), $(foreach B, $(ALL_B),\
$(eval $(call MERKLE_SUM_V_B,$(MAX_DELTA),$(EXP_DELTA),v$(V)_b$(B)))\
))))

define MERKLE_SCALE_SUM_V_B
merkle_scale_expD$(1)-all/$(2)/Makefile: Makefile_scale.tmpl2 merkle_scale_expD$(1)-all/$(2)/.gitignore Makefile
	@mkdir -p "$$(@D)"
	@V=$$(shell expr match "$(2)" 'v\([0-9][0-9]*\)_b[0-9][0-9]*') ; B=$$(shell expr match "$(2)" 'v[0-9][0-9]*_b\([0-9][0-9]*\)') ; \
      sed -e 's|<sys_size>|$(SYSTEM_SIZE_SCALE)|g' \
          -e "s|<dat1>|../v$$$${V}_b$$$${B}_p0.1/merkle_scale.dat|g" \
          -e "s|<dat2>|../v$$$${V}_b$$$${B}_p0.01/merkle_scale.dat|g" \
          -e "s|<dat3>|../v$$$${V}_b$$$${B}_p0.001/merkle_scale.dat|g" \
          -e "s|<dat4>|../v$$$${V}_b$$$${B}_p0.0001/merkle_scale.dat|g" \
          -e 's|<dat5>||g' \
          -e "s|<title1>|merkle_{v$$$${V}, b$$$${B}, P_{1e}0.1}|g" \
          -e "s|<title2>|merkle_{v$$$${V}, b$$$${B}, P_{1e}0.01}|g" \
          -e "s|<title3>|merkle_{v$$$${V}, b$$$${B}, P_{1e}0.001}|g" \
          -e "s|<title4>|merkle_{v$$$${V}, b$$$${B}, P_{1e}0.0001}|g" \
          -e 's|<title5>||g' \
          -e 's|<morecommands>|absoluteRedundancy=1;|g' \
          -e 's|../eval_data_inc.gp|../../eval_data_inc.gp|g' \
          -e 's|../coldefs_eval_point.gp|../../coldefs_eval_point.gp|g' < $$< > $$@

merkle_scale_expD$(1)-all/$(2): merkle_scale_expD$(1)-all/$(2)/Makefile $(foreach P1E, $(ALL_P), merkle_scale_expD$(1)-all/$(2)_p$(P1E)/merkle_scale.dat)
	
endef
$(foreach EXP_DELTA, as_fprob, $(foreach V, $(ALL_V), $(foreach B, $(ALL_B),\
$(eval $(call MERKLE_SCALE_SUM_V_B,$(EXP_DELTA),v$(V)_b$(B)))\
)))

define MERKLE_SUM_B_P
merkle_0-$(1)_expD$(2)-all/$(3)/Makefile: Makefile.tmpl2 merkle_0-$(1)_expD$(2)-all/$(3)/.gitignore Makefile
	@mkdir -p "$$(@D)"
	@B=$$(shell expr match "$(3)" 'b\([0-9][0-9]*\)_p[0-9][.0-9]*') ; P=$$(shell expr match "$(3)" 'b[0-9][0-9]*_p\([0-9][.0-9]*\)') ; \
      sed -e 's|<sys_size>|$(SYSTEM_SIZE)|g' \
          -e "s|<dat1>|../v2_b$$$${B}_p$$$${P}/merkle.dat|g" \
          -e "s|<dat2>|../v3_b$$$${B}_p$$$${P}/merkle.dat|g" \
          -e "s|<dat3>|../v4_b$$$${B}_p$$$${P}/merkle.dat|g" \
          -e "s|<dat4>|../v8_b$$$${B}_p$$$${P}/merkle.dat|g" \
          -e "s|<dat5>|../v16_b$$$${B}_p$$$${P}/merkle.dat|g" \
          -e "s|<title1>|merkle_{v2        }|g" \
          -e "s|<title2>|merkle_{v3        }|g" \
          -e "s|<title3>|merkle_{v4        }|g" \
          -e "s|<title4>|merkle_{v8        }|g" \
          -e "s|<title5>|merkle_{v16       }|g" \
          -e "s|<morecommands>|absoluteRedundancy=1;stepSize=0$$(shell bc <<< "scale=2; $(1)/5");plot_label='b=$$$${B}, P_{1e}=$$$${P}\';|g" \
          -e 's|../eval_fprob.gp|../../eval_fprob.gp|g' \
          -e 's|../coldefs_eval_point.gp|../../coldefs_eval_point.gp|g' < $$< > $$@

merkle_0-$(1)_expD$(2)-all/$(3): merkle_0-$(1)_expD$(2)-all/$(3)/Makefile $(foreach V, 2 3 4 8 16, merkle_0-$(1)_expD$(2)-all/v$(V)_$(3)/merkle.dat)
	
endef
$(foreach MAX_DELTA, 1 10 100, $(foreach EXP_DELTA, $(EXP_DELTA_LIST), $(foreach B, $(ALL_B), $(foreach P, $(ALL_P),\
$(eval $(call MERKLE_SUM_B_P,$(MAX_DELTA),$(EXP_DELTA),b$(B)_p$(P)))\
))))

define MERKLE_SCALE_SUM_B_P
merkle_scale_expD$(1)-all/$(2)/Makefile: Makefile_scale.tmpl2 merkle_scale_expD$(1)-all/$(2)/.gitignore Makefile
	@mkdir -p "$$(@D)"
	@B=$$(shell expr match "$(2)" 'b\([0-9][0-9]*\)_p[0-9][.0-9]*') ; P=$$(shell expr match "$(2)" 'b[0-9][0-9]*_p\([0-9][.0-9]*\)') ; \
      sed -e 's|<sys_size>|$(SYSTEM_SIZE_SCALE)|g' \
          -e "s|<dat1>|../v2_b$$$${B}_p$$$${P}/merkle_scale.dat|g" \
          -e "s|<dat2>|../v4_b$$$${B}_p$$$${P}/merkle_scale.dat|g" \
          -e "s|<dat3>|../v16_b$$$${B}_p$$$${P}/merkle_scale.dat|g" \
          -e 's|<dat4>||g' \
          -e 's|<dat5>||g' \
          -e "s|<title1>|merkle_{v2, b$$$${B}, P_{1e}$$$${P}}|g" \
          -e "s|<title2>|merkle_{v4, b$$$${B}, P_{1e}$$$${P}}|g" \
          -e "s|<title3>|merkle_{v16, b$$$${B}, P_{1e}$$$${P}}|g" \
          -e 's|<title4>||g' \
          -e 's|<title5>||g' \
          -e 's|<morecommands>|absoluteRedundancy=1;|g' \
          -e 's|../eval_data_inc.gp|../../eval_data_inc.gp|g' \
          -e 's|../coldefs_eval_point.gp|../../coldefs_eval_point.gp|g' < $$< > $$@

merkle_scale_expD$(1)-all/$(2): merkle_scale_expD$(1)-all/$(2)/Makefile $(foreach V, 2 4 16, merkle_scale_expD$(1)-all/v$(V)_$(2)/merkle_scale.dat)
	
endef
$(foreach EXP_DELTA, as_fprob, $(foreach B, $(ALL_B), $(foreach P, $(ALL_P),\
$(eval $(call MERKLE_SCALE_SUM_B_P,$(EXP_DELTA),b$(B)_p$(P)))\
)))

define MERKLE_SUM_V_P
merkle_0-$(1)_expD$(2)-all/$(3)/Makefile: Makefile.tmpl2 merkle_0-$(1)_expD$(2)-all/$(3)/.gitignore Makefile
	@mkdir -p "$$(@D)"
	@V=$$(shell expr match "$(3)" 'v\([0-9][0-9]*\)_p[0-9][.0-9]*') ; P=$$(shell expr match "$(3)" 'v[0-9][0-9]*_p\([0-9][.0-9]*\)') ; \
      sed -e 's|<sys_size>|$(SYSTEM_SIZE)|g' \
          -e "s|<dat1>|../v$$$${V}_b1_p$$$${P}/merkle.dat|g" \
          -e "s|<dat2>|../v$$$${V}_b2_p$$$${P}/merkle.dat|g" \
          -e "s|<dat3>|../v$$$${V}_b3_p$$$${P}/merkle.dat|g" \
          -e "s|<dat4>|../v$$$${V}_b4_p$$$${P}/merkle.dat|g" \
          -e "s|<dat5>|../v$$$${V}_b8_p$$$${P}/merkle.dat|g" \
          -e "s|<title1>|merkle_{b1        }|g" \
          -e "s|<title2>|merkle_{b2        }|g" \
          -e "s|<title3>|merkle_{b3        }|g" \
          -e "s|<title4>|merkle_{b4        }|g" \
          -e "s|<title5>|merkle_{b8        }|g" \
          -e "s|<morecommands>|absoluteRedundancy=1;stepSize=0$$(shell bc <<< "scale=2; $(1)/5");plot_label='v=$$$${V}, P_{1e}=$$$${P}';|g" \
          -e 's|../eval_fprob.gp|../../eval_fprob.gp|g' \
          -e 's|../coldefs_eval_point.gp|../../coldefs_eval_point.gp|g' < $$< > $$@

merkle_0-$(1)_expD$(2)-all/$(3): merkle_0-$(1)_expD$(2)-all/$(3)/Makefile $(foreach B, 1 2 3 4 8, merkle_0-$(1)_expD$(2)-all/$(subst _,_b$(B)_,$(3))/merkle.dat)
	
endef
$(foreach MAX_DELTA, 1 10 100, $(foreach EXP_DELTA, $(EXP_DELTA_LIST), $(foreach V, $(ALL_V), $(foreach P, $(ALL_P),\
$(eval $(call MERKLE_SUM_V_P,$(MAX_DELTA),$(EXP_DELTA),v$(V)_p$(P)))\
))))

define MERKLE_SCALE_SUM_V_P
merkle_scale_expD$(1)-all/$(2)/Makefile: Makefile_scale.tmpl2 merkle_scale_expD$(1)-all/$(2)/.gitignore Makefile
	@mkdir -p "$$(@D)"
	@V=$$(shell expr match "$(2)" 'v\([0-9][0-9]*\)_p[0-9][.0-9]*') ; P=$$(shell expr match "$(2)" 'v[0-9][0-9]*_p\([0-9][.0-9]*\)') ; \
      sed -e 's|<sys_size>|$(SYSTEM_SIZE_SCALE)|g' \
          -e "s|<dat1>|../v$$$${V}_b1_p$$$${P}/merkle_scale.dat|g" \
          -e "s|<dat2>|../v$$$${V}_b3_p$$$${P}/merkle_scale.dat|g" \
          -e "s|<dat3>|../v$$$${V}_b8_p$$$${P}/merkle_scale.dat|g" \
          -e 's|<dat4>||g' \
          -e 's|<dat5>||g' \
          -e "s|<title1>|merkle_{v$$$${V}, b1, P_{1e}$$$${P}}|g" \
          -e "s|<title2>|merkle_{v$$$${V}, b3, P_{1e}$$$${P}}|g" \
          -e "s|<title3>|merkle_{v$$$${V}, b8, P_{1e}$$$${P}}|g" \
          -e 's|<title4>||g' \
          -e 's|<title5>||g' \
          -e 's|<morecommands>|absoluteRedundancy=1;|g' \
          -e 's|../eval_data_inc.gp|../../eval_data_inc.gp|g' \
          -e 's|../coldefs_eval_point.gp|../../coldefs_eval_point.gp|g' < $$< > $$@

merkle_scale_expD$(1)-all/$(2): merkle_scale_expD$(1)-all/$(2)/Makefile $(foreach B, 1 3 8, merkle_scale_expD$(1)-all/$(subst _,_b$(B)_,$(2))/merkle_scale.dat)
	
endef
$(foreach EXP_DELTA, as_fprob, $(foreach V, $(ALL_V), $(foreach P, $(ALL_P),\
$(eval $(call MERKLE_SCALE_SUM_V_P,$(EXP_DELTA),v$(V)_p$(P)))\
)))

merkle: merkle-all merkle_dists-all merkle_scale-all
	

# v4_b3_p0.001_d10_n32000-60000,4000
MERKLE_EFF_PROB_EXTRACT_V='v\([0-9][0-9]*\)_b[0-9][0-9]*_p[0-9][.0-9]*_d[0-9][0-9]*_n[0-9][0-9]*-[0-9][0-9]*,[0-9][0-9]*'
MERKLE_EFF_PROB_EXTRACT_B='v[0-9][0-9]*_b\([0-9][0-9]*\)_p[0-9][.0-9]*_d[0-9][0-9]*_n[0-9][0-9]*-[0-9][0-9]*,[0-9][0-9]*'
MERKLE_EFF_PROB_EXTRACT_P='v[0-9][0-9]*_b[0-9][0-9]*_p\([0-9][.0-9]*\)_d[0-9][0-9]*_n[0-9][0-9]*-[0-9][0-9]*,[0-9][0-9]*'
MERKLE_EFF_PROB_EXTRACT_D='v[0-9][0-9]*_b[0-9][0-9]*_p[0-9][.0-9]*_d\([0-9][0-9]*\)_n[0-9][0-9]*-[0-9][0-9]*,[0-9][0-9]*'
MERKLE_EFF_PROB_EXTRACT_START='v[0-9][0-9]*_b[0-9][0-9]*_p[0-9][.0-9]*_d[0-9][0-9]*_n\([0-9][0-9]*\)-[0-9][0-9]*,[0-9][0-9]*'
MERKLE_EFF_PROB_EXTRACT_END='v[0-9][0-9]*_b[0-9][0-9]*_p[0-9][.0-9]*_d[0-9][0-9]*_n[0-9][0-9]*-\([0-9][0-9]*\),[0-9][0-9]*'
MERKLE_EFF_PROB_EXTRACT_STEPSIZE='v[0-9][0-9]*_b[0-9][0-9]*_p[0-9][.0-9]*_d[0-9][0-9]*_n[0-9][0-9]*-[0-9][0-9]*,\([0-9][0-9]*\)'

merkle_effective_prob/%/merkle_custom.dat: merkle_effective_prob/Makefile
	@echo " executing merkle_eff_prob $*"
	@mkdir -p "$(@D)"
	V=$(shell expr match "$*" $(MERKLE_EFF_PROB_EXTRACT_V)) ; B=$(shell expr match "$*" $(MERKLE_EFF_PROB_EXTRACT_B)) ; P=$(shell expr match "$*" $(MERKLE_EFF_PROB_EXTRACT_P)) ; D=$(shell expr match "$*" $(MERKLE_EFF_PROB_EXTRACT_D)) ; START=$(shell expr match "$*" $(MERKLE_EFF_PROB_EXTRACT_START)) ; END=$(shell expr match "$*" $(MERKLE_EFF_PROB_EXTRACT_END)) ; STEPSIZE=$(shell expr match "$*" $(MERKLE_EFF_PROB_EXTRACT_STEPSIZE)) ; STEPS=`expr '(' $$END - $$START ')' / $$STEPSIZE` ; ./rr_eval.sh -a merkle_custom -n "$$START" -c "$$V,$$B,$$P,as_fprob,$$STEPSIZE,$$STEPS,[update],$$D,data_count" -t "merkle_{v$$V, b$$B, P_{1e}$$P}" -d "$(@D)" -r $(EVAL_REPEATS) -s "$$STEPSIZE" > "$(@D)/eval.log"

MERKLE_2_EXTRACT_V='v\([0-9][0-9]*\)'

merkle_2_p0.01_expDas_fprob/%/merkle_custom.dat: merkle_2_p0.01_expDas_fprob/Makefile
	@echo " executing merkle_2_p0.01_expDas_fprob $*"
	@mkdir -p "$(@D)"
	V=$(shell expr match "$*" $(MERKLE_2_EXTRACT_V)) ; P=0.01 ; D=2 ; STEPSIZE=1 ; STEPS=15 ; ./rr_eval.sh -a merkle_custom -n "$(SYSTEM_SIZE)" -c "$$V,1,$$P,as_fprob,$$STEPSIZE,$$STEPS,[update,regen],$$D,merkle_bucket" -t "merkle_{v$$V, P_{1e}0.01}" -d "$(@D)" -r $(EVAL_REPEATS) -s "$$STEPSIZE" > "$(@D)/eval.log"

merkle_2_p0.01_expDas_fprob-all: merkle_2_p0.01_expDas_fprob/Makefile $(foreach V, $(shell seq -s" " 2 16), merkle_2_p0.01_expDas_fprob/v$(V)/merkle_custom.dat)
	

# note: we must have the same dependencies as the specific rules
#       -> otherwise this rule may be chosen instead
# also we need to order this (default) target as the last one so it has no
# precedence over the special targets above (in older Make versions)
%/Makefile: Makefile.tmpl %/.gitignore Makefile
	@mkdir -p "$(@D)"
	@cp $< $@
	@rm "$*/.gitignore"
