#!/bin/#!/usr/bin/env bash

###############################################################################
# diygit.sh - created by John Moore-Levesque, 12/5/2017
# Usage:
#    sh diygit.sh <FILE> [FORK (optional)]
###############################################################################


###############################################################################
# Variables
# FILE: input parameter - do *NOT* provide full path"
# PROJ: project directory - derived from file
# DATE: current date - used to create file backup
# FL: used tp make symlink
###############################################################################
DATE=`date +'%Y%m%d%H%M%S'`
FL="${1}"
FILE="${1}.${DATE}"
PROJ="`echo ${1} | cut -f1 -d'.'`"
if [[ "${2}" == "FORK" ]]
then
  read -p "FOrking ${1} - what do you want to call the new file? " newfile
  OLDPROJ="`echo ${1} | cut -f1 -d'.'`"
  OLDFILE="${OLDPROJ}/${1}"
  FILE="$newfile.${DATE}"
  FL="$newfile"
  PROJ="`echo $newfile | cut -f1 -d'.'`"
fi

# Does PROJ exist? If not, make it
if [ ! -d "${PROJ}" ]
then
  mkdir ${PROJ}
fi

if [[ "${2}" == "FORK" ]]
then
  if [ -f "${OLDFILE}" ]
  then
    cp ${OLDFILE} ${PROJ}/${FILE}
  else
    echo "${OLDFILE} doesn't exist - exiting."
    exit
  fi
fi

# Does the file exist at the root level? If so, ask if you want to move to PROJ
if [ -f "${FILE}" ]
then
  if [ ! -L "${FILE}" ]
  then
    read -p "${FILE} already exists, but not as part of a diygit project - do you want to work on this file? (y or n) " choice
    case ${choice^^} in
      Y)
        mv ${FILE} ${PROJ}
        ;;
      N)
        echo "OK - just remember that the diygit version of your file will be in ${PROJ}/${FILE}"
        ;;
      *)
        echo "Invalid choice, proceeding - remember that the diygit version of your file will be in ${PROJ}/${FILE}"
        ;;
    esac
  fi
fi

cd ${PROJ}

# Copy current symlink (i.e., HEAD) to ${FILE} for editing
cp ${FL} ${FILE}
vim ${FILE}

# If there's no CHANGELOG, create it
if [ ! -f CHANGELOG ]
then
  touch CHANGELOG
fi

# Create temporary file for CHANGELOG
echo "/--------------------------/" > /tmp/change.$$
echo "CHANGELOG Date: `date +%Y-%m-%d:%H:%M:%S`" >> /tmp/change.$$
if [[ "${2}" == "FORK" ]]
then
  echo "Forked ${1} to create ${FILE}" >> /tmp/change.$$
fi

vim /tmp/change.$$
echo "" >> /tmp/change.$$

# Checksums to see if changes were made
FILEMD5=`md5sum ${FILE} | cut -f1 -d' '`
CHMD5=`md5sum ${FL} | cut -f1 -d' '`

# If changes were made, then write change.$$ to CHANGELOG
# Otherwise remove FILE (since no changes were made)
if [[ "${FILEMD5}" != "${CHMD5}" ]]
then
  # repoint symlink
  rm ${FL}
  ln -s ${FILE} ${FL}
  echo "Repointed ${FL} symlink to ${PROJ}/${FILE} at `date`" >> /tmp/change.$$
  echo "New HEAD checksum is ${FILEMD5}" >> /tmp/change.$$
  echo "Old HEAD checksum is ${CHMD5}" >> /tmp/change.$$
  echo "" >> /tmp/change.$$
  cat CHANGELOG >> /tmp/change.$$
  cat /tmp/change.$$ > CHANGELOG
else
  rm ${FILE}
fi

# Remove change.$$
rm /tmp/change.$$
