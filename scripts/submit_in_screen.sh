#!/bin/bash

screen -dmS bnb_sim bash -c './submit_grid.sh > submit_sim_process_$(date +%Y%m%d_%H%M%S).log 2>&1'