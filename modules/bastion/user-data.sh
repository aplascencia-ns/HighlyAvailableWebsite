#!/bin/bash

cat > index.html <<EOF
<h1>Bastion is running...</h1>
<?php
$instance_id = file_get_contents("http://instance-data/latest/meta-data/instance-id");
echo "You've reached instance ", $instance_id, "\n";
?>
EOF

nohup busybox httpd -f -p ${server_port} &
