@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View For GL Period'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_RPT_GL_ACCOUNT_PERIOD as select from I_FiscalYearPeriod
{
    key FiscalYear,
    key FiscalPeriod as Period
}
where FiscalPeriod <= '013'
and FiscalYearVariant = 'K4'
