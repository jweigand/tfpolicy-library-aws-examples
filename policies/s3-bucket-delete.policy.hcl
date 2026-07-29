# S3 Bucket Delete Protection
#
# Prevents deletion of an S3 bucket that is still actively referenced by any
# of the following data source types in the plan:
#
#   - aws_s3_bucket_object_lock_configuration
#   - aws_s3_bucket_replication_configuration
#   - aws_s3control_access_points
#   - aws_s3control_multi_region_access_points
#
# Also prevents deletion if the bucket contains any objects (checked via
# aws_s3_objects with max_keys = 1 for performance).
#
# Each data source is looked up inline via core::getdatasource() scoped to the
# specific bucket being destroyed using prior_attrs.bucket.
#
# NOTE: This policy fires only on destroy operations. prior_attrs.bucket holds
# the bucket name as it existed before the destroy was planned.

resource_policy "aws_s3_bucket" "delete_protection" {
  operations = ["delete"]

  locals {
    bucket = prior_attrs.bucket

    # Look up each data source filtered to this specific bucket.
    object_lock_config = core::try(core::getdatasource("aws_s3_bucket_object_lock_configuration", {
      bucket = local.bucket
    }), null)

    replication_config = core::try(core::getdatasource("aws_s3_bucket_replication_configuration", {
      bucket = local.bucket
    }), null)

    access_point = core::try(core::getdatasource("aws_s3control_access_points", {
      bucket = local.bucket
    }), null)

    multi_region_access_point = core::try(core::getdatasource("aws_s3control_multi_region_access_points", {
      bucket = local.bucket
    }), null)

    # Check for any objects in the bucket; max_keys = 1 limits the API call to a single key for efficiency.
    bucket_objects = core::try(core::getdatasource("aws_s3_objects", {
      bucket   = local.bucket
      max_keys = 1
    }), null)

    has_object_lock_config        = local.object_lock_config != null
    has_replication_config        = local.replication_config != null
    has_access_point              = local.access_point != null
    has_multi_region_access_point = local.multi_region_access_point != null
    has_objects                   = local.bucket_objects != null && core::length(core::try(local.bucket_objects.keys, [])) > 0
  }

  enforce {
    condition     = !local.has_object_lock_config
    error_message = "S3 bucket '${local.bucket}' cannot be deleted: it is referenced by an aws_s3_bucket_object_lock_configuration data source. Remove or update the object lock configuration before deleting the bucket."
  }

  enforce {
    condition     = !local.has_replication_config
    error_message = "S3 bucket '${local.bucket}' cannot be deleted: it is referenced by an aws_s3_bucket_replication_configuration data source. Remove or update the replication configuration before deleting the bucket."
  }

  enforce {
    condition     = !local.has_access_point
    error_message = "S3 bucket '${local.bucket}' cannot be deleted: it is referenced by an aws_s3control_access_points data source. Remove or reassociate the access point before deleting the bucket."
    info_message  = "access points output ${jsonencode(local.access_point)}"
  }

  enforce {
    condition     = !local.has_multi_region_access_point
    error_message = "S3 bucket '${local.bucket}' cannot be deleted: it is referenced by an aws_s3control_multi_region_access_points data source. Remove or reassociate the multi-region access point before deleting the bucket."
  }

  enforce {
    condition     = !local.has_objects
    error_message = "S3 bucket '${local.bucket}' cannot be deleted: the bucket still contains objects. Empty the bucket before deleting it."
  }
}
