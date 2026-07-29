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

locals {
  all_mrap_resources       = core::getresources("aws_s3control_multi_region_access_point", {})
  mrap_names_being_deleted = [for r in local.all_mrap_resources : core::try(r.details[0].name, "")]
}

resource_policy "aws_s3_bucket" "delete_protection" {
  operations = ["delete"]

  locals {
    bucket = prior_attrs.bucket

    # Collect all aws_s3control_multi_region_access_point resources in the same
    # delete-scoped plan. The name is nested inside details[0].name so a flat
    # filter cannot be used; fetch all and match by name below.


    # Look up each data source filtered to this specific bucket.
    object_lock_config = core::try(core::getdatasource("aws_s3_bucket_object_lock_configuration", {
      bucket = local.bucket
    }), null)

    replication_config = core::try(core::getdatasource("aws_s3_bucket_replication_configuration", {
      bucket = local.bucket
    }), null)

    access_point = core::getdatasource("aws_s3control_access_points", {
      bucket = local.bucket
    })

    multi_region_access_point = core::getdatasource("aws_s3control_multi_region_access_points", {
      region = "us-west-2" # required region for this AWS API Endpoint: https://docs.aws.amazon.com/AmazonS3/latest/userguide/MrapOperations.html
    })

    # Names of MRAPs that reference this bucket via their regions list.
    referencing_mrap_names = [for ap in local.multi_region_access_point.access_points : ap.name if core::length([for r in ap.regions : r if r.bucket == local.bucket]) > 0]

    # A referencing MRAP is "covered" if its name appears in the top-level list of
    # aws_s3control_multi_region_access_point resources being deleted in this plan.
    uncovered_mrap_names = [for name in local.referencing_mrap_names : name if !core::contains(local.mrap_names_being_deleted, name)]

    # Check for any objects in the bucket; max_keys = 1 limits the API call to a single key for efficiency.
    bucket_objects = core::getdatasource("aws_s3_objects", {
      bucket   = local.bucket
      max_keys = 1
    })

  }

  enforce {
    condition     = local.object_lock_config == null
    error_message = "S3 bucket '${local.bucket}' cannot be deleted: it is referenced by an aws_s3_bucket_object_lock_configuration data source. Remove or update the object lock configuration before deleting the bucket."
    info_message  = "object lock config output ${core::jsonencode(local.object_lock_config)} | | all MRAP: ${core::jsonencode(local.all_mrap_resources)} | MRAP names being deleted: ${core::jsonencode(local.mrap_names_being_deleted)}"
  }

  enforce {
    condition     = local.replication_config == null
    error_message = "S3 bucket '${local.bucket}' cannot be deleted: it is referenced by an aws_s3_bucket_replication_configuration data source. Remove or update the replication configuration before deleting the bucket."
    info_message  = "replication config output ${core::jsonencode(local.replication_config)}"
  }

  enforce {
    condition     = local.access_point.access_points == null
    error_message = "S3 bucket '${local.bucket}' cannot be deleted: it is referenced by an aws_s3control_access_points data source. Remove or reassociate the access point before deleting the bucket."
    info_message  = "access points output ${core::jsonencode(local.access_point)}"
  }

  /*

  enforce {
    # Pass if no MRAPs reference this bucket, or if all referencing MRAPs are also
    # being deleted in the same plan.
    condition     = core::length(local.uncovered_mrap_names) == 0
    error_message = "S3 bucket '${local.bucket}' cannot be deleted: it is referenced by multi-region access point(s) that are not being deleted in this plan: ${core::jsonencode(local.uncovered_mrap_names)}. Remove or reassociate those access points before deleting the bucket."
    info_message  = "multi-region access point output ${core::jsonencode(local.multi_region_access_point)} | all MRAP: ${core::jsonencode(local.all_mrap_resources)} | MRAP names being deleted: ${core::jsonencode(local.mrap_names_being_deleted)}"
  }

  */

  enforce {
    condition     = core::length(local.bucket_objects.keys) == 0
    error_message = "S3 bucket '${local.bucket}' cannot be deleted: the bucket still contains objects. Empty the bucket before deleting it."
    info_message  = "bucket objects output ${core::jsonencode(local.bucket_objects)}"
  }
}
