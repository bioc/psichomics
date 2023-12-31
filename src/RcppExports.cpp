// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <Rcpp.h>

using namespace Rcpp;

#ifdef RCPP_USE_GLOBAL_ROSTREAM
Rcpp::Rostream<true>&  Rcpp::Rcout = Rcpp::Rcpp_cout_get();
Rcpp::Rostream<false>& Rcpp::Rcerr = Rcpp::Rcpp_cerr_get();
#endif

// psiFastCalc
NumericMatrix psiFastCalc(const NumericMatrix& mat, const NumericVector incA, const NumericVector incB, const NumericVector excA, const NumericVector excB, const int minReads);
RcppExport SEXP _psichomics_psiFastCalc(SEXP matSEXP, SEXP incASEXP, SEXP incBSEXP, SEXP excASEXP, SEXP excBSEXP, SEXP minReadsSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< const NumericMatrix& >::type mat(matSEXP);
    Rcpp::traits::input_parameter< const NumericVector >::type incA(incASEXP);
    Rcpp::traits::input_parameter< const NumericVector >::type incB(incBSEXP);
    Rcpp::traits::input_parameter< const NumericVector >::type excA(excASEXP);
    Rcpp::traits::input_parameter< const NumericVector >::type excB(excBSEXP);
    Rcpp::traits::input_parameter< const int >::type minReads(minReadsSEXP);
    rcpp_result_gen = Rcpp::wrap(psiFastCalc(mat, incA, incB, excA, excB, minReads));
    return rcpp_result_gen;
END_RCPP
}
// psiFastCalc2
NumericMatrix psiFastCalc2(const NumericMatrix& mat, const List& inc, const List& exc, const int minReads);
RcppExport SEXP _psichomics_psiFastCalc2(SEXP matSEXP, SEXP incSEXP, SEXP excSEXP, SEXP minReadsSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< const NumericMatrix& >::type mat(matSEXP);
    Rcpp::traits::input_parameter< const List& >::type inc(incSEXP);
    Rcpp::traits::input_parameter< const List& >::type exc(excSEXP);
    Rcpp::traits::input_parameter< const int >::type minReads(minReadsSEXP);
    rcpp_result_gen = Rcpp::wrap(psiFastCalc2(mat, inc, exc, minReads));
    return rcpp_result_gen;
END_RCPP
}
// discardVastToolsByCvg
DataFrame discardVastToolsByCvg(DataFrame psi, DataFrame eventData, int qualityCol, CharacterVector scoresToDiscard);
RcppExport SEXP _psichomics_discardVastToolsByCvg(SEXP psiSEXP, SEXP eventDataSEXP, SEXP qualityColSEXP, SEXP scoresToDiscardSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< DataFrame >::type psi(psiSEXP);
    Rcpp::traits::input_parameter< DataFrame >::type eventData(eventDataSEXP);
    Rcpp::traits::input_parameter< int >::type qualityCol(qualityColSEXP);
    Rcpp::traits::input_parameter< CharacterVector >::type scoresToDiscard(scoresToDiscardSEXP);
    rcpp_result_gen = Rcpp::wrap(discardVastToolsByCvg(psi, eventData, qualityCol, scoresToDiscard));
    return rcpp_result_gen;
END_RCPP
}

static const R_CallMethodDef CallEntries[] = {
    {"_psichomics_psiFastCalc", (DL_FUNC) &_psichomics_psiFastCalc, 6},
    {"_psichomics_psiFastCalc2", (DL_FUNC) &_psichomics_psiFastCalc2, 4},
    {"_psichomics_discardVastToolsByCvg", (DL_FUNC) &_psichomics_discardVastToolsByCvg, 4},
    {NULL, NULL, 0}
};

RcppExport void R_init_psichomics(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
