# S3 Bucket Delete Protection
#
# Prevents deletion of an S3 bucket that is still actively referenced by any
# of the following data source types:
#
#   - aws_s3_bucket_object_lock_configuration
#   - aws_s3_bucket_replication_configuration
#   - aws_s3control_access_points
#   - aws_s3control_multi_region_access_points
#
# Also prevents deletion if the bucket contains any objects (checked via
# aws_s3_objects with max_keys = 1 for performance).
#
# NOTE: This policy fires only on destroy operations. prior_attrs.bucket holds
# the bucket name as it existed before the destroy was planned.

resource_policy "aws_s3_bucket" "delete_checks_base" {
  enforcement_level = "mandatory_overridable"
  operations        = ["delete"]

  locals {
    bucket = prior_attrs.bucket

    object_lock_config = core::try(core::getdatasource("aws_s3_bucket_object_lock_configuration", {
      bucket = local.bucket
    }), null)

    replication_config = core::try(core::getdatasource("aws_s3_bucket_replication_configuration", {
      bucket = local.bucket
    }), null)

    # Check for any objects in the bucket; max_keys = 1 limits the API call to a single key for efficiency.
    bucket_objects = core::try(core::getdatasource("aws_s3_objects", {
      bucket   = local.bucket
      max_keys = 1
    }), null)
  }

  enforce {
    condition     = local.object_lock_config == null
    error_message = "S3 bucket '${local.bucket}' cannot be deleted because it is configured for object lock."
  }

  enforce {
    condition     = local.replication_config == null
    error_message = "S3 bucket '${local.bucket}' cannot be deleted: it is referenced by an aws_s3_bucket_replication_configuration data source. Remove or update the replication configuration before deleting the bucket."
    info_message  = "replication config output ${core::jsonencode(local.replication_config)}"
  }

  enforce {
    condition     = local.bucket_objects == null || core::length(local.bucket_objects.keys) == 0
    error_message = "S3 bucket '${local.bucket}' cannot be deleted because it still contains objects."
  }
}

resource_policy "aws_s3_bucket" "delete_checks_access_points" {
  enforcement_level = "mandatory_overridable"
  operations        = ["delete"]

  locals {
    bucket = prior_attrs.bucket

    access_point = core::try(core::getdatasource("aws_s3control_access_points", {
      bucket = local.bucket
    }), null)

    referenced_access_points = local.access_point == null ? [] : local.access_point.access_points == null ? [] : local.access_point.access_points

    all_multi_region_access_points = core::getdatasource("aws_s3control_multi_region_access_points", {
      region = "us-west-2" # required region for this AWS API Endpoint: https://docs.aws.amazon.com/AmazonS3/latest/userguide/MrapOperations.html
    })

    referenced_multi_region_access_points = local.all_multi_region_access_points.access_points == null ? [] : [for mrap in local.all_multi_region_access_points.access_points : mrap if core::length([for r in mrap.regions : r if r.bucket == local.bucket]) > 0]
  }

  enforce {
    condition     = core::length(local.referenced_access_points) == 0
    error_message = <<-EOT
    S3 bucket '${local.bucket}' cannot be deleted because it is referenced by the following access point(s):
    ${core::join("", [for ap in local.referenced_access_points : core::yamlencode({ (ap.name) = { access_point_arn = ap.access_point_arn, alias = ap.alias } })])}
    EOT
  }

  # The data source returns all MRAPs for the account; search access_points[*].regions[*].bucket
  # for a match against the bucket being deleted.
  enforce {
    condition     = core::length(local.referenced_multi_region_access_points) == 0
    error_message = <<-EOT
    S3 bucket '${local.bucket}' cannot be deleted because it is referenced by the following multi-region access point(s):
    ${core::join("", [for mrap in local.referenced_multi_region_access_points : core::yamlencode({ (mrap.name) = { alias = mrap.alias, created = mrap.created_at } })])}
    EOT
  }
}
