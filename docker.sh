docker_image="headmelted/codebuilder:$ARCHIE_ARCH"

# Run the container unconfined and with CAP_SYS_ADMIN, for bind mounts
echo "Binding workspace and executing script for [${ARCHIE_STRATEGY}/${ARCHIE_ARCH}]";

docker run \
--security-opt apparmor:unconfined --cap-add SYS_ADMIN \
-e GITHUB_TOKEN=$GITHUB_TOKEN \
-e ARCHIE_STRATEGY \
-e ARCHIE_ARCH \
-e ARCHIE_HOST_DEPENDENCIES \
-e ARCHIE_TARGET_DEPENDENCIES \
-v $(pwd):/root/build \
-v $(pwd)/out:/root/output \
$docker_image /bin/bash -c "cd /root/build && . /root/kitchen/tools/archie_start_build.sh";