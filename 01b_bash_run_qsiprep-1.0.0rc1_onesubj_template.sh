#!/bin/bash
# !!!!!!!!!!!!!!!!!!!!!!
# This script was created from a template in:
# EXPERIMENT/code/preproc/qsiprep/templates
# Template name: 
# 01b_bash_run_qsiprep-1.0.0rc1_onesubj_template.sh
# !!!!!!!!!!!!!!!!!!!!!!

SUBJ=$1

EXPERIMENT=/proj/belgerlab/projects
STUDY=STUDYNAME
BIDSDIR=$EXPERIMENT/data/$STUDY
FS_LIC=$EXPERIMENT/tools/fmriprep/license.txt
QSIPREPIMG=$EXPERIMENT/tools/qsiprep/qsiprep-1.0.0rc1.sif
FMRIPREPVER="fmriprep-23.2.0"
FREESURFDIR=$BIDSDIR/derivatives/$FMRIPREPVER/sourcedata/freesurfer

OUTDIR=${QSIPREPIMG/"$EXPERIMENT/tools/qsiprep/"/""}
OUTDIR=${OUTDIR/".sif"/""}
WORKDIR=$EXPERIMENT/work/${OUTDIR}_work/$STUDY
OUTDIR=$BIDSDIR/derivatives/$OUTDIR
if [ ! -d $WORKDIR ]; then
  mkdir -p $WORKDIR
fi

mkdir -p $OUTDIR
# Change permissions
GROUPNAME=`ls -l $BIDSDIR | tail -n 1 | awk -F ' ' '{print$4}'`
chgrp $GROUPNAME $OUTDIR
chmod g+ws $OUTDIR

# Run singularity image
# singularity run -e --bind /proj $QSIPREPIMG $BIDSDIR $OUTDIR participant --participant_label $SUBJ --nthreads 16 --omp-nthreads 4 --work-dir $WORKDIR --notrack --output-resolution 2 --fs-license-file $FS_LIC --freesurfer-input $FREESURFDIR
# This was the old QSIPrep call
# singularity run -e --bind /proj $QSIPREPIMG $BIDSDIR $OUTDIR participant --participant_label $SUBJ --nthreads 16 --omp-nthreads 4 --work-dir $WORKDIR --notrack --output-resolution 2 --fs-license-file $FS_LIC --freesurfer-input $FREESURFDIR --skip_bids_validation
singularity run -e --bind /proj $QSIPREPIMG $BIDSDIR $OUTDIR participant --participant-label $SUBJ --nthreads 16 --omp-nthreads 4 -w $WORKDIR --notrack --output-resolution 2 --fs-license-file $FS_LIC --skip-bids-validation

# Change permissions
chgrp -R $GROUPNAME $OUTDIR/qsiprep/${SUBJ}*
chmod -R g+ws $OUTDIR/qsiprep/${SUBJ}*
chgrp -R $GROUPNAME $WORKDIR
chmod -R g+ws $WORKDIR

# Delete currently running file
if [ -f $OUTDIR/${SUBJ}_currently_running.txt ]; then
  rm -f $OUTDIR/${SUBJ}_currently_running.txt
fi

