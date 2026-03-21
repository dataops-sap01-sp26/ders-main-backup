// ═══════════════════════════════════════════════════════════════════════════════
// INTERFACE CDS: G/L Account Balances Data
// PURPOSE: Query G/L balances from ACDOCA (Universal Journal)
// NOTE: For S/4HANA - uses ACDOCA. For ECC, use BSEG/BKPF instead.
// ═══════════════════════════════════════════════════════════════════════════════
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'G/L Account Balances - Data'
@Metadata.ignorePropagatedAnnotations: true

@Analytics.dataCategory: #CUBE

define view entity ZI_DRS_GL01
  as select from acdoca as Journal
  
  -- Association to G/L Account Master
  association [0..1] to skat as _GLText 
    on  $projection.GLAccount    = _GLText.saknr
    and $projection.ChartOfAccounts = _GLText.ktopl
    and _GLText.spras = $session.system_language
{
      // ─────────────────────────────────────────────────────────────────────────
      // DIMENSIONS
      // ─────────────────────────────────────────────────────────────────────────
      key Journal.rbukrs                            as CompanyCode,
      key Journal.gjahr                             as FiscalYear,
      key Journal.poper                             as FiscalPeriod,
      key Journal.racct                             as GLAccount,
      key Journal.rldnr                             as Ledger,
      
      // G/L Account Text
      _GLText.txt50                                 as GLAccountName,
      
      // Chart of Accounts
      Journal.ktopl                                 as ChartOfAccounts,
      
      // Currency
      Journal.rhcur                                 as LocalCurrency,
      
      // ─────────────────────────────────────────────────────────────────────────
      // MEASURES (Aggregated)
      // ─────────────────────────────────────────────────────────────────────────
      @Semantics.amount.currencyCode: 'LocalCurrency'
      @Aggregation.default: #SUM
      case when Journal.drcrk = 'S' then Journal.hsl else cast( 0 as abap.curr( 23, 2 ) ) end as DebitAmount,
      
      @Semantics.amount.currencyCode: 'LocalCurrency'
      @Aggregation.default: #SUM  
      case when Journal.drcrk = 'H' then Journal.hsl else cast( 0 as abap.curr( 23, 2 ) ) end as CreditAmount,
      
      @Semantics.amount.currencyCode: 'LocalCurrency'
      @Aggregation.default: #SUM
      Journal.hsl                                   as BalanceAmount,
      
      // ─────────────────────────────────────────────────────────────────────────
      // ASSOCIATIONS
      // ─────────────────────────────────────────────────────────────────────────
      _GLText
}
where
  Journal.rldnr = '0L'  -- Leading Ledger only
