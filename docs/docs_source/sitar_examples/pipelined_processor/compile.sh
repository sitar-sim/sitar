#!/bin/bash
set -e
sitar translate PipelinedProcessor.sitar
sitar compile -d Output/ -d ./
