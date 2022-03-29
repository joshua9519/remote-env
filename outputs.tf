output "ssh_config" {
  value = <<EOF
Host remote-dev
  ForwardAgent yes
  User ext_${replace(replace(local.email, ".", "_"), "@", "_")}
  IdentityFile ~/.ssh/remote_dev
  CheckHostIP no
  HashKnownHosts no
  IdentitiesOnly yes
  StrictHostKeyChecking no
  UserKnownHostsFile ~/.ssh/remote_dev_known_hosts
  ProxyCommand /usr/bin/python3 -S ~/google-cloud-sdk/lib/gcloud.py compute start-iap-tunnel remote-dev %p --listen-on-stdin --project=${var.project_id} --zone=${local.zone} --verbosity=warning
  ProxyUseFdpass no
EOF
}
