@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job History Analytics'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
@Analytics.dataCategory: #CUBE
@Analytics.internalName: #LOCAL

define view entity ZI_DRS_JOB_HISTORY_ANALYTICS
  as select from zdrs_job_history as History
{
      /** DIMENSIONS **/
  key job_hist_uuid          as JobHistUuid,
      cast( substring( cast( start_timestamp as abap.char(23) ), 1, 8 )
            as abap.dats )   as JobDate,
      case job_status
        when 'F' then 'Finished'
        when 'A' then 'Failed'
        when 'S' then 'Scheduled'
        when 'R' then 'Running'
        else job_status
      end                    as JobStatus,
      case job_status
        when 'F' then 3   // Green
        when 'A' then 1   // Red
        when 'S' then 5   // Blue
        else 0
      end                    as JobStatusCriticality,
      job_name               as JobName,
      report_id              as ReportId,
      message                as Message,
      start_timestamp        as StartTimestamp,
      end_timestamp          as EndTimestamp,
      duration_ms            as DurationMs,
      created_by             as CreatedBy,

      /** MEASURES **/
      @Aggregation.default: #SUM
      cast( 1 as abap.int4 ) as JobCount

}
