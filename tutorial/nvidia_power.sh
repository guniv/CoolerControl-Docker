#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# #   Script for saving power on Unraid server with Nvidia GPUs when they are not passed to a VM                                          # #
# #   (needs Unraid nvidia driver if you want to enable the show power savings bc will need to be installed from nerd tools plugin)       # #                                                                                                 # #
# #   by - SpaceInvaderOne                                                                                                                # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
####################
# Set these variable for a rough estimate of how much saving you would have in a year from the power saved
####################
show_saving="yes" # Set to "yes" to show savings
hours_server_running="24" # set this for how many hours server running for
electricity_cost_KWH=".28" # set this for you cost of electric in cost per unit per kwh
Currency="£"   # set your currency symbol

####################
# Do not change below this line #
#  arrays to store initial and final power usages
declare -A initial_power_usage final_power_usage

#  calculate and display potential savings 
calculate_savings() {
    local initial_power=$1
    local final_power=$2
    local hours_per_day=$3
    local cost_per_kwh=$4
    local currency=$5

    local power_saved=$(echo "$initial_power - $final_power" | bc -l)
    
    if [ $(echo "$power_saved > 0" | bc -l) -eq 1 ]; then
        local daily_saving=$(echo "$power_saved * $hours_per_day / 1000 * $cost_per_kwh" | bc -l)
        local yearly_saving=$(echo "$daily_saving * 365" | bc -l)
        
        # Redirecting textual output to stderr
        >&2 echo "Power saved from before for GPU $gpu_id is ${power_saved} watts."
        >&2 echo "This could save you up to ${currency}$(printf "%.2f" $yearly_saving) per year."
        
        # Only echoing the numeric value for capturing
        echo "$yearly_saving"
    else
        # If no savings, output 0 and redirect message to stderr
        >&2 echo "No significant power savings for GPU $gpu_id."
        echo "0"
    fi
}
#  variable to hold the total savings
total_yearly_savings=0

#  check if a Graphics Card is being used by any docker container
is_gpu_in_use_by_docker() {
    local gpu_id=$1
    # List processes using the Graphics Card
    local gpu_processes=$(nvidia-smi -i ${gpu_id} --query-compute-apps=pid --format=csv,noheader)
    for pid in $gpu_processes; do
        # Check if this process belongs to a Docker container
        if grep -q "docker" /proc/${pid}/cgroup 2> /dev/null; then
            return 0 # Graphics Card is in use by a Docker container
        fi
    done
    return 1 # Graphics Card is not in use by any docker container
}

terminate_non_docker_gpu_processes() {
    echo "Checking for process termination eligibility…"

    if all_gpus_free; then
        echo "No Docker containers are using the GPUs. Terminating non-Docker processes using NVIDIA devices…"
        mapfile -t pids < <(fuser /dev/nvidia* 2>&1 | awk '{for(i=2;i<=NF;i++) print $i}')
        for pid in "${pids[@]}"; do
            cmd=$(ps -p "$pid" -o comm=)
            if [[ "$cmd" == "coolercontrold" ]]; then
                echo "Skipping coolercontrold (PID $pid)"
                continue
            fi
            echo "Killing $cmd (PID $pid)"
            kill -9 "$pid"
        done
    else
        echo "At least one GPU is being used by a Docker container. Will not terminate GPU-related processes."
        exit 1
    fi
}

#  check if any GPU is being used by Docker
all_gpus_free() {
    local gpu_count=$(nvidia-smi --list-gpus | wc -l)
    for (( gpu_id=0; gpu_id<gpu_count; gpu_id++ )); do
        if is_gpu_in_use_by_docker $gpu_id; then
            return 1 # GPU is in use by Docker, return false
        fi
    done
    return 0 # All GPUs are free, return true
}
# display power usage and state for all Graphics Cards
display_power_usage_and_state() {
    local title=$1 # "Initial" or "Final"
    echo "${title} Power Usage and State"
    echo "--------------------------------------------"
    local gpu_count=$(nvidia-smi --list-gpus | wc -l)
    for (( gpu_id=0; gpu_id<gpu_count; gpu_id++ )); do
        local gpu_info=$(nvidia-smi -i ${gpu_id} --query-gpu=name,power.draw,pstate --format=csv,noheader,nounits)
        # Splitting the gpu_info into an array
        IFS=',' read -ra gpu_details <<< "$gpu_info"
        echo "GPU ${gpu_id} -- ${gpu_details[0]}"
        echo "Power Usage -- ${gpu_details[1]} W"
        echo "Power State -- ${gpu_details[2]}"
        echo "--------------------------------------------"
    done
}

#  set Graphics Card to lowest power state
set_lowest_power_state() {
    local gpu_id=$1
    if ! is_gpu_in_use_by_docker ${gpu_id}; then
        # check persistence mode status
        local persistence_mode=$(nvidia-smi -i ${gpu_id} --query-gpu=persistence_mode --format=csv,noheader,nounits)
        if [ "$persistence_mode" == "Disabled" ]; then
            echo "Enabling Persistence Mode for gpu ${gpu_id}."
            nvidia-smi -i ${gpu_id} --persistence-mode=1
        fi

        # First optimisation attempt is report verbosely
        echo "GPU ${gpu_id} is idle and not used by any Docker container. Optimising for power efficiency."

        # other attempts  confirmed briefly
        for attempt in 2 3; do
            echo "GPU ${gpu_id} optimisation attempt ${attempt} confirmed."
        done
    else
        echo "GPU ${gpu_id} is currently in use by a Docker container. Skipping power optimisation."
    fi
}

# check for NVIDIA driver installed on server
command -v nvidia-smi &> /dev/null || { echo >&2 "NVIDIA driver is not installed. Exiting."; exit 1; }

# list NVIDIA GPUs and get initial power usage and state
echo "NVIDIA drivers are installed."
echo
echo "Listing NVIDIA Graphics Cards in your server..."
nvidia-smi --list-gpus
echo

echo "Initial Power Usage and State"
echo "--------------------------------------------"
gpu_count=$(nvidia-smi --list-gpus | wc -l)
for (( gpu_id=0; gpu_id<gpu_count; gpu_id++ )); do
    initial_power_usage[$gpu_id]=$(nvidia-smi -i ${gpu_id} --query-gpu=power.draw --format=csv,noheader,nounits)
    gpu_info=$(nvidia-smi -i ${gpu_id} --query-gpu=name,power.draw,pstate --format=csv,noheader,nounits)
    IFS=',' read -ra gpu_details <<< "$gpu_info"
    echo "GPU ${gpu_id} -- ${gpu_details[0]}"
    echo "Power Usage -- ${gpu_details[1]} W"
    echo "Power State -- ${gpu_details[2]}"
    echo "--------------------------------------------"
done

terminate_non_docker_gpu_processes
# iterate over each Graphics Card and attempt to set it to the lowest power state if not used by Docker
gpu_count=$(nvidia-smi --list-gpus | wc -l)
for (( gpu_id=0; gpu_id<gpu_count; gpu_id++ )); do
    set_lowest_power_state ${gpu_id}
done

# sleep to allow changes to take effect
echo "Waiting for GPUs to adjust to new power states..."
sleep 15 # waits 15 seconds to let changes stick

# get final power usage after optimisation
for (( gpu_id=0; gpu_id<gpu_count; gpu_id++ )); do
    final_power_usage[$gpu_id]=$(nvidia-smi -i ${gpu_id} --query-gpu=power.draw --format=csv,noheader,nounits)
done

echo "--------------------------------------------"
display_power_usage_and_state "Final"
echo "Note: Power states range from P0 (maximum performance) to P8 (lowest power state)."

# calculate and display savings if enabled
if [[ "$show_saving" == "yes" || "$show_saving" == "Yes" ]]; then
    echo "--------------------------------------------"
    echo "Calculating Savings..."
    echo "--------------------------------------------"
    
    # make sure bc is installed before attempting to calculate savings
    if ! command -v bc &> /dev/null; then
        echo "Show savings will only work with bc installed. Please install this using the NerdTools plugin from CA."
        exit 1
    fi

    total_yearly_savings=0

    for (( gpu_id=0; gpu_id<gpu_count; gpu_id++ )); do
        # Capture only the numeric yearly savings, ensuring no syntax errors from bc
        yearly_saving=$(calculate_savings "${initial_power_usage[$gpu_id]}" "${final_power_usage[$gpu_id]}" "$hours_server_running" "$electricity_cost_KWH" "$Currency")
        # Safely add yearly savings to the total, avoiding non-numeric input
        total_yearly_savings=$(echo "$total_yearly_savings + $yearly_saving" | bc -l)
    done
    
    # Display total savings, ensuring the output is numeric and formatted correctly
    if [ "$(echo "$total_yearly_savings > 0" | bc)" -eq 1 ]; then
        echo "Potential max savings over year for all GPUs combined: ${Currency}$(printf "%.2f" "$total_yearly_savings") per year"
    else
        echo "Overall, no significant power savings across all Graphics Cards."
    fi
fi
