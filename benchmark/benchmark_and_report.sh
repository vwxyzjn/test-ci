#### Step 1: create a work directory:
# this is necessary because another github action job will remove
# the entire directory, which slurm depends on.
# https://stackoverflow.com/questions/4632028/how-to-create-a-temporary-directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORK_DIR=$(mktemp -d)
if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
  echo "Could not create temp dir"
  exit 1
fi
function cleanup {      
  rm -rf "$WORK_DIR"
  echo "Deleted temp working directory $WORK_DIR"
}
trap cleanup EXIT
cp -r "$DIR" "$WORK_DIR"
cd "$WORK_DIR"


#### Step 2: actual work starts:
bash benchmark/benchmark.sh > output.txt

# Extract Job IDs into an array
job_ids=($(grep "Job ID:" output.txt | awk '{print $3}'))

# Extract WANDB_TAGS into an array
WANDB_TAGS=($(grep "WANDB_TAGS:" output.txt | awk '{print $2}'))
WANDB_TAGS=($(echo $WANDB_TAGS | tr "," "\n"))

# Print to verify
echo "Job IDs: ${job_ids[@]}"
echo "WANDB_TAGS: ${WANDB_TAGS[@]}"

TAGS_STRING="?tag=${WANDB_TAGS[0]}"
FOLDER_STRING="${WANDB_TAGS[0]}"
for tag in "${WANDB_TAGS[@]:1}"; do
    TAGS_STRING+="&tag=$tag"
    FOLDER_STRING+="_$tag"
done

echo "TAGS_STRING: $TAGS_STRING"
echo "FOLDER_STRING: $FOLDER_STRING"

TAGS_STRING=$TAGS_STRING FOLDER_STRING=$FOLDER_STRING sbatch --dependency=afterany:$job_ids benchmark/post_github_comment.sbatch
