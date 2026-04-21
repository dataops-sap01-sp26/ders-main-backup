@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Subscription Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Search.searchable: true
define view entity ZI_VH_DRS_SUBSCR
  as select from zdrs_subscr
{
      @UI.hidden: true
  key subscr_uuid   as SubscrUuid,

      @EndUserText.label: 'Subscription ID'
      @UI.lineItem: [{ position: 10 }]
  key subscr_id     as SubscrId,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @EndUserText.label: 'Description'
      @UI.lineItem: [{ position: 20 }]
      subscr_name   as SubscrName,

      @EndUserText.label: 'Report ID'
      @UI.lineItem: [{ position: 30 }]
      report_id     as ReportId,

      @EndUserText.label: 'Format'
      @UI.lineItem: [{ position: 40 }]
      output_format as OutputFormat,

      @EndUserText.label: 'Email To'
      @UI.lineItem: [{ position: 50 }]
      email_to      as EmailTo,

      @EndUserText.label: 'Email CC'
      @UI.lineItem: [{ position: 60 }]
      email_cc      as EmailCc,

      @EndUserText.label: 'Status'
      @UI.lineItem: [{ position: 70 }]
      status        as Status,

      @EndUserText.label: 'Company Code'
      @UI.lineItem: [{ position: 80 }]
      bukrs         as Bukrs,

      @EndUserText.label: 'Created By'
      @UI.lineItem: [{ position: 90 }]
      created_by    as CreatedBy,

      @EndUserText.label: 'Created At'
      @UI.lineItem: [{ position: 100 }]
      created_at    as CreatedAt
}
