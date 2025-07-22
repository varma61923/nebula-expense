import 'dart:math';

/// Comprehensive offline financial calculators service
class CalculatorService {
  /// Calculate EMI (Equated Monthly Installment)
  static EMIResult calculateEMI({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
  }) {
    if (principal <= 0 || annualInterestRate < 0 || tenureMonths <= 0) {
      throw ArgumentError('Invalid input parameters');
    }

    final monthlyRate = annualInterestRate / 100 / 12;
    
    double emi;
    if (monthlyRate == 0) {
      // No interest case
      emi = principal / tenureMonths;
    } else {
      emi = principal * 
            (monthlyRate * pow(1 + monthlyRate, tenureMonths)) / 
            (pow(1 + monthlyRate, tenureMonths) - 1);
    }

    final totalAmount = emi * tenureMonths;
    final totalInterest = totalAmount - principal;

    return EMIResult(
      emi: emi,
      totalAmount: totalAmount,
      totalInterest: totalInterest,
      principal: principal,
      interestRate: annualInterestRate,
      tenure: tenureMonths,
    );
  }

  /// Calculate SIP (Systematic Investment Plan)
  static SIPResult calculateSIP({
    required double monthlyInvestment,
    required double expectedAnnualReturn,
    required int tenureYears,
  }) {
    if (monthlyInvestment <= 0 || expectedAnnualReturn < 0 || tenureYears <= 0) {
      throw ArgumentError('Invalid input parameters');
    }

    final monthlyRate = expectedAnnualReturn / 100 / 12;
    final totalMonths = tenureYears * 12;
    
    double maturityAmount;
    if (monthlyRate == 0) {
      // No return case
      maturityAmount = monthlyInvestment * totalMonths;
    } else {
      maturityAmount = monthlyInvestment * 
                     (pow(1 + monthlyRate, totalMonths) - 1) / 
                     monthlyRate * 
                     (1 + monthlyRate);
    }

    final totalInvestment = monthlyInvestment * totalMonths;
    final totalReturns = maturityAmount - totalInvestment;

    return SIPResult(
      maturityAmount: maturityAmount,
      totalInvestment: totalInvestment,
      totalReturns: totalReturns,
      monthlyInvestment: monthlyInvestment,
      expectedReturn: expectedAnnualReturn,
      tenure: tenureYears,
    );
  }

  /// Calculate Compound Interest
  static CompoundInterestResult calculateCompoundInterest({
    required double principal,
    required double annualInterestRate,
    required int tenureYears,
    required int compoundingFrequency, // 1=Annual, 2=Semi-annual, 4=Quarterly, 12=Monthly, 365=Daily
  }) {
    if (principal <= 0 || annualInterestRate < 0 || tenureYears <= 0 || compoundingFrequency <= 0) {
      throw ArgumentError('Invalid input parameters');
    }

    final rate = annualInterestRate / 100;
    final amount = principal * pow(1 + rate / compoundingFrequency, compoundingFrequency * tenureYears);
    final interest = amount - principal;

    return CompoundInterestResult(
      finalAmount: amount,
      totalInterest: interest,
      principal: principal,
      interestRate: annualInterestRate,
      tenure: tenureYears,
      compoundingFrequency: compoundingFrequency,
    );
  }

  /// Calculate Simple Interest
  static SimpleInterestResult calculateSimpleInterest({
    required double principal,
    required double annualInterestRate,
    required double tenureYears,
  }) {
    if (principal <= 0 || annualInterestRate < 0 || tenureYears <= 0) {
      throw ArgumentError('Invalid input parameters');
    }

    final interest = principal * (annualInterestRate / 100) * tenureYears;
    final amount = principal + interest;

    return SimpleInterestResult(
      finalAmount: amount,
      totalInterest: interest,
      principal: principal,
      interestRate: annualInterestRate,
      tenure: tenureYears,
    );
  }

  /// Calculate Loan Affordability
  static LoanAffordabilityResult calculateLoanAffordability({
    required double monthlyIncome,
    required double monthlyExpenses,
    required double annualInterestRate,
    required int tenureMonths,
    double maxEMIRatio = 0.4, // Maximum 40% of income for EMI
  }) {
    if (monthlyIncome <= 0 || monthlyExpenses < 0 || annualInterestRate < 0 || tenureMonths <= 0) {
      throw ArgumentError('Invalid input parameters');
    }

    final disposableIncome = monthlyIncome - monthlyExpenses;
    final maxEMI = min(disposableIncome, monthlyIncome * maxEMIRatio);
    
    if (maxEMI <= 0) {
      return LoanAffordabilityResult(
        maxLoanAmount: 0,
        maxEMI: 0,
        disposableIncome: disposableIncome,
        recommendedEMI: 0,
      );
    }

    final monthlyRate = annualInterestRate / 100 / 12;
    
    double maxLoanAmount;
    if (monthlyRate == 0) {
      maxLoanAmount = maxEMI * tenureMonths;
    } else {
      maxLoanAmount = maxEMI * 
                     (pow(1 + monthlyRate, tenureMonths) - 1) / 
                     (monthlyRate * pow(1 + monthlyRate, tenureMonths));
    }

    return LoanAffordabilityResult(
      maxLoanAmount: maxLoanAmount,
      maxEMI: maxEMI,
      disposableIncome: disposableIncome,
      recommendedEMI: maxEMI * 0.8, // 80% of max EMI for safety
    );
  }

  /// Calculate Budget Allocation (50/30/20 rule)
  static BudgetAllocationResult calculateBudgetAllocation({
    required double monthlyIncome,
    double needsPercentage = 50,
    double wantsPercentage = 30,
    double savingsPercentage = 20,
  }) {
    if (monthlyIncome <= 0) {
      throw ArgumentError('Monthly income must be positive');
    }

    if (needsPercentage + wantsPercentage + savingsPercentage != 100) {
      throw ArgumentError('Percentages must sum to 100');
    }

    return BudgetAllocationResult(
      monthlyIncome: monthlyIncome,
      needs: monthlyIncome * needsPercentage / 100,
      wants: monthlyIncome * wantsPercentage / 100,
      savings: monthlyIncome * savingsPercentage / 100,
      needsPercentage: needsPercentage,
      wantsPercentage: wantsPercentage,
      savingsPercentage: savingsPercentage,
    );
  }

  /// Calculate Retirement Planning
  static RetirementPlanningResult calculateRetirementPlanning({
    required int currentAge,
    required int retirementAge,
    required double currentSavings,
    required double monthlyContribution,
    required double expectedAnnualReturn,
    required double inflationRate,
    required double desiredMonthlyIncome,
  }) {
    if (currentAge >= retirementAge || currentAge < 0 || retirementAge < 0) {
      throw ArgumentError('Invalid age parameters');
    }

    final yearsToRetirement = retirementAge - currentAge;
    final monthsToRetirement = yearsToRetirement * 12;
    final monthlyReturn = expectedAnnualReturn / 100 / 12;
    
    // Calculate future value of current savings
    final futureValueCurrentSavings = currentSavings * pow(1 + expectedAnnualReturn / 100, yearsToRetirement);
    
    // Calculate future value of monthly contributions
    double futureValueContributions = 0;
    if (monthlyReturn > 0) {
      futureValueContributions = monthlyContribution * 
                                (pow(1 + monthlyReturn, monthsToRetirement) - 1) / 
                                monthlyReturn;
    } else {
      futureValueContributions = monthlyContribution * monthsToRetirement;
    }
    
    final totalRetirementCorpus = futureValueCurrentSavings + futureValueContributions;
    
    // Calculate required corpus considering inflation
    final inflationAdjustedIncome = desiredMonthlyIncome * pow(1 + inflationRate / 100, yearsToRetirement);
    final requiredCorpus = inflationAdjustedIncome * 12 * 25; // 25x annual expenses rule
    
    final shortfall = requiredCorpus - totalRetirementCorpus;

    return RetirementPlanningResult(
      totalRetirementCorpus: totalRetirementCorpus,
      requiredCorpus: requiredCorpus,
      shortfall: shortfall > 0 ? shortfall : 0,
      inflationAdjustedIncome: inflationAdjustedIncome,
      yearsToRetirement: yearsToRetirement,
      isOnTrack: shortfall <= 0,
    );
  }

  /// Calculate Tax Planning (Basic)
  static TaxPlanningResult calculateTaxPlanning({
    required double annualIncome,
    required double currentInvestments,
    required double maxTaxSavingLimit,
    required List<TaxSlab> taxSlabs,
  }) {
    if (annualIncome <= 0 || currentInvestments < 0 || maxTaxSavingLimit < 0) {
      throw ArgumentError('Invalid input parameters');
    }

    final taxableIncome = annualIncome - currentInvestments;
    double taxWithoutSaving = _calculateTax(annualIncome, taxSlabs);
    double taxWithCurrentSaving = _calculateTax(taxableIncome, taxSlabs);
    
    final additionalSavingPossible = maxTaxSavingLimit - currentInvestments;
    final maxTaxableIncome = annualIncome - maxTaxSavingLimit;
    double taxWithMaxSaving = _calculateTax(maxTaxableIncome, taxSlabs);
    
    return TaxPlanningResult(
      annualIncome: annualIncome,
      taxWithoutSaving: taxWithoutSaving,
      taxWithCurrentSaving: taxWithCurrentSaving,
      taxWithMaxSaving: taxWithMaxSaving,
      currentTaxSaving: taxWithoutSaving - taxWithCurrentSaving,
      maxPossibleTaxSaving: taxWithoutSaving - taxWithMaxSaving,
      additionalInvestmentNeeded: additionalSavingPossible > 0 ? additionalSavingPossible : 0,
    );
  }

  static double _calculateTax(double income, List<TaxSlab> taxSlabs) {
    double tax = 0;
    double remainingIncome = income;
    
    for (final slab in taxSlabs) {
      if (remainingIncome <= 0) break;
      
      final taxableInThisSlab = min(remainingIncome, slab.upperLimit - slab.lowerLimit);
      tax += taxableInThisSlab * slab.rate / 100;
      remainingIncome -= taxableInThisSlab;
    }
    
    return tax;
  }

  /// Calculate Emergency Fund
  static EmergencyFundResult calculateEmergencyFund({
    required double monthlyExpenses,
    required double currentSavings,
    int monthsOfExpenses = 6,
  }) {
    if (monthlyExpenses <= 0 || currentSavings < 0 || monthsOfExpenses <= 0) {
      throw ArgumentError('Invalid input parameters');
    }

    final requiredAmount = monthlyExpenses * monthsOfExpenses;
    final shortfall = requiredAmount - currentSavings;

    return EmergencyFundResult(
      requiredAmount: requiredAmount,
      currentSavings: currentSavings,
      shortfall: shortfall > 0 ? shortfall : 0,
      monthsOfExpensesCovered: currentSavings / monthlyExpenses,
      isAdequate: shortfall <= 0,
    );
  }

  /// Calculate Investment Returns
  static InvestmentReturnResult calculateInvestmentReturn({
    required double initialInvestment,
    required double finalValue,
    required double tenureYears,
  }) {
    if (initialInvestment <= 0 || finalValue <= 0 || tenureYears <= 0) {
      throw ArgumentError('Invalid input parameters');
    }

    final absoluteReturn = finalValue - initialInvestment;
    final absoluteReturnPercentage = (absoluteReturn / initialInvestment) * 100;
    final cagr = (pow(finalValue / initialInvestment, 1 / tenureYears) - 1) * 100;

    return InvestmentReturnResult(
      initialInvestment: initialInvestment,
      finalValue: finalValue,
      absoluteReturn: absoluteReturn,
      absoluteReturnPercentage: absoluteReturnPercentage,
      cagr: cagr,
      tenure: tenureYears,
    );
  }
}

// Result classes
class EMIResult {
  final double emi;
  final double totalAmount;
  final double totalInterest;
  final double principal;
  final double interestRate;
  final int tenure;

  EMIResult({
    required this.emi,
    required this.totalAmount,
    required this.totalInterest,
    required this.principal,
    required this.interestRate,
    required this.tenure,
  });
}

class SIPResult {
  final double maturityAmount;
  final double totalInvestment;
  final double totalReturns;
  final double monthlyInvestment;
  final double expectedReturn;
  final int tenure;

  SIPResult({
    required this.maturityAmount,
    required this.totalInvestment,
    required this.totalReturns,
    required this.monthlyInvestment,
    required this.expectedReturn,
    required this.tenure,
  });
}

class CompoundInterestResult {
  final double finalAmount;
  final double totalInterest;
  final double principal;
  final double interestRate;
  final int tenure;
  final int compoundingFrequency;

  CompoundInterestResult({
    required this.finalAmount,
    required this.totalInterest,
    required this.principal,
    required this.interestRate,
    required this.tenure,
    required this.compoundingFrequency,
  });
}

class SimpleInterestResult {
  final double finalAmount;
  final double totalInterest;
  final double principal;
  final double interestRate;
  final double tenure;

  SimpleInterestResult({
    required this.finalAmount,
    required this.totalInterest,
    required this.principal,
    required this.interestRate,
    required this.tenure,
  });
}

class LoanAffordabilityResult {
  final double maxLoanAmount;
  final double maxEMI;
  final double disposableIncome;
  final double recommendedEMI;

  LoanAffordabilityResult({
    required this.maxLoanAmount,
    required this.maxEMI,
    required this.disposableIncome,
    required this.recommendedEMI,
  });
}

class BudgetAllocationResult {
  final double monthlyIncome;
  final double needs;
  final double wants;
  final double savings;
  final double needsPercentage;
  final double wantsPercentage;
  final double savingsPercentage;

  BudgetAllocationResult({
    required this.monthlyIncome,
    required this.needs,
    required this.wants,
    required this.savings,
    required this.needsPercentage,
    required this.wantsPercentage,
    required this.savingsPercentage,
  });
}

class RetirementPlanningResult {
  final double totalRetirementCorpus;
  final double requiredCorpus;
  final double shortfall;
  final double inflationAdjustedIncome;
  final int yearsToRetirement;
  final bool isOnTrack;

  RetirementPlanningResult({
    required this.totalRetirementCorpus,
    required this.requiredCorpus,
    required this.shortfall,
    required this.inflationAdjustedIncome,
    required this.yearsToRetirement,
    required this.isOnTrack,
  });
}

class TaxPlanningResult {
  final double annualIncome;
  final double taxWithoutSaving;
  final double taxWithCurrentSaving;
  final double taxWithMaxSaving;
  final double currentTaxSaving;
  final double maxPossibleTaxSaving;
  final double additionalInvestmentNeeded;

  TaxPlanningResult({
    required this.annualIncome,
    required this.taxWithoutSaving,
    required this.taxWithCurrentSaving,
    required this.taxWithMaxSaving,
    required this.currentTaxSaving,
    required this.maxPossibleTaxSaving,
    required this.additionalInvestmentNeeded,
  });
}

class EmergencyFundResult {
  final double requiredAmount;
  final double currentSavings;
  final double shortfall;
  final double monthsOfExpensesCovered;
  final bool isAdequate;

  EmergencyFundResult({
    required this.requiredAmount,
    required this.currentSavings,
    required this.shortfall,
    required this.monthsOfExpensesCovered,
    required this.isAdequate,
  });
}

class InvestmentReturnResult {
  final double initialInvestment;
  final double finalValue;
  final double absoluteReturn;
  final double absoluteReturnPercentage;
  final double cagr;
  final double tenure;

  InvestmentReturnResult({
    required this.initialInvestment,
    required this.finalValue,
    required this.absoluteReturn,
    required this.absoluteReturnPercentage,
    required this.cagr,
    required this.tenure,
  });
}

class TaxSlab {
  final double lowerLimit;
  final double upperLimit;
  final double rate;

  TaxSlab({
    required this.lowerLimit,
    required this.upperLimit,
    required this.rate,
  });
}
