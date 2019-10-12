#!/bin/bash
set -eu

function has_built_uboot() {
	if [ -f $1/uboot.img ]; then
		echo 1
	else
		echo 0
	fi
}

function has_built_kernel() {
	local KIMG=kernel.img
	if [ -f $1/${KIMG} ]; then
		echo 1
	else
		echo 0
	fi
}

function has_built_kernel_modules() {
	local OUTDIR=${2}
	local SOC=rk3399
	if [ -d ${OUTDIR}/output_${SOC}_kmodules ]; then
		echo 1
	else
		echo 0
	fi
}

