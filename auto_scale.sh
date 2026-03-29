#!/bin/bash

# ===============================
# Configuration
# ===============================
INSTANCE_NAME="auto-instance-1"
ZONE="us-central1-a"
MACHINE_TYPE="e2-medium"
CPU_THRESHOLD=75
MEM_THRESHOLD=75
CHECK_INTERVAL=10  # seconds

# Path to your service account JSON
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/vcc-assignment-488814-883cac623c68.json"

# Flag to ensure we only create 1 instance
INSTANCE_CREATED=0

# ===============================
# Function to get CPU and Memory usage
# ===============================
get_usage() {
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')  # CPU idle -> usage
    MEM=$(free | grep Mem | awk '{print $3/$2 * 100}')
}

# ===============================
# Main loop
# ===============================
while [ $INSTANCE_CREATED -eq 0 ]; do
    get_usage
    CPU_INT=${CPU%.*}
    MEM_INT=${MEM%.*}

    echo "CPU: $CPU_INT%, Memory: $MEM_INT%"

    if [ "$CPU_INT" -ge "$CPU_THRESHOLD" ] || [ "$MEM_INT" -ge "$MEM_THRESHOLD" ]; then
        echo "Threshold exceeded! Launching GCP instance..."

        gcloud compute instances create "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --machine-type="$MACHINE_TYPE" \
            --image-family=ubuntu-2204-lts \
            --image-project=ubuntu-os-cloud \
            --metadata=startup-script='#!/bin/bash
              sudo apt update
              sudo apt install -y python3 python3-pip
              echo "Hello from GCP VM!" > /home/ubuntu/message.txt'

        echo "GCP instance created successfully!"
        INSTANCE_CREATED=1
    fi

    sleep "$CHECK_INTERVAL"
done

