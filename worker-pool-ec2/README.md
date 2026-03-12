# AWS EC2 Worker Pool Template

Deploy a private Spacelift worker pool on AWS EC2 with autoscaling.

## Repo Structure

```
templates-workbench/                    ← repo root
└── worker-pool-ec2/                    ← this template
    ├── template.yaml                   ← Self-Service v2 template definition
    ├── stacks/
    │   └── worker-pool/
    │       └── main.tf                 ← Terraform code (spacelift_worker_pool + EC2 module)
    ├── WORKSHOP.md                     ← Step-by-step workshop guide
    └── README.md                       ← This file
```

## How It Works

The `template.yaml` defines a "Self-Service v2" template that points to the Terraform code in `stacks/worker-pool/`.

The `main.tf` creates:
1. A `spacelift_worker_pool` resource — generates token + private key automatically
2. An EC2 ASG via the official `terraform-aws-spacelift-workerpool-on-ec2` module (v5.5.0)
3. A Lambda autoscaler that scales workers based on Spacelift queue depth

Credentials flow directly from Terraform — **no manual openssl, no base64, no copy-paste.**

## Module Version

Uses `v5.5.0` (requires AWS provider >= 6.0.0).
For AWS provider 5.x, change to `v4.4.4` in `main.tf`.
