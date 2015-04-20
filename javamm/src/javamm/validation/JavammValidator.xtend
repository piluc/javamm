/*
 * generated by Xtext
 */
package javamm.validation

import com.google.inject.Inject
import java.util.ArrayList
import javamm.javamm.JavammAdditionalXVariableDeclaration
import javamm.javamm.JavammArrayConstructorCall
import javamm.javamm.JavammBranchingStatement
import javamm.javamm.JavammBreakStatement
import javamm.javamm.JavammContinueStatement
import javamm.javamm.JavammMethod
import javamm.javamm.JavammPackage
import javamm.javamm.JavammProgram
import javamm.javamm.Main
import javamm.util.JavammModelUtil
import javamm.util.JavammNodeModelUtil
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtext.common.types.JvmFormalParameter
import org.eclipse.xtext.common.types.JvmOperation
import org.eclipse.xtext.util.Wrapper
import org.eclipse.xtext.validation.Check
import org.eclipse.xtext.xbase.XAbstractFeatureCall
import org.eclipse.xtext.xbase.XAbstractWhileExpression
import org.eclipse.xtext.xbase.XAssignment
import org.eclipse.xtext.xbase.XBasicForLoopExpression
import org.eclipse.xtext.xbase.XDoWhileExpression
import org.eclipse.xtext.xbase.XExpression
import org.eclipse.xtext.xbase.XFeatureCall
import org.eclipse.xtext.xbase.XMemberFeatureCall
import org.eclipse.xtext.xbase.XReturnExpression
import org.eclipse.xtext.xbase.XSwitchExpression
import org.eclipse.xtext.xbase.XVariableDeclaration
import org.eclipse.xtext.xbase.XbasePackage
import org.eclipse.xtext.xbase.typesystem.util.Multimaps2
import org.eclipse.xtext.xbase.validation.XbaseValidator
import javamm.scoping.JavammOperatorMapping
import org.eclipse.xtext.xtype.XImportDeclaration

//import org.eclipse.xtext.validation.Check

/**
 * Custom validation rules. 
 *
 * see http://www.eclipse.org/Xtext/documentation.html#validation
 */
class JavammValidator extends XbaseValidator {
	
	public static val PREFIX = "javamm."
	
	public static val NOT_ARRAY_TYPE = PREFIX + "NotArrayType"
	public static val INVALID_BRANCHING_STATEMENT = PREFIX + "InvalidBranchingStatement"
	public static val MISSING_SEMICOLON = PREFIX + "MissingSemicolon"
	public static val MISSING_PARENTHESES = PREFIX + "MissingParentheses"
	public static val DUPLICATE_METHOD = PREFIX + "DuplicateMethod"
	public static val ARRAY_CONSTRUCTOR_EITHER_DIMENSION_EXPRESSION_OR_INITIALIZER = PREFIX + "ArrayConstructorEitherDimensionExpressionOrInitializer"
	public static val ARRAY_CONSTRUCTOR_BOTH_DIMENSION_EXPRESSION_AND_INITIALIZER = PREFIX + "ArrayConstructorBothDimensionExpressionAndInitializer"
	public static val ARRAY_CONSTRUCTOR_DIMENSION_EXPRESSION_AFTER_EMPTY_DIMENSION = PREFIX + "ArrayConstructorDimensionExpressionAfterEmptyExpression"
	
	static val xbasePackage = XbasePackage.eINSTANCE;
	
	static val javammPackage = JavammPackage.eINSTANCE;
	
	val semicolonStatements = #{
		JavammBranchingStatement,
		XVariableDeclaration,
		XDoWhileExpression,
		XReturnExpression,
		XAssignment,
		XAbstractFeatureCall
	}

	val featuresForRequiredSemicolon = #{
		xbasePackage.XBlockExpression_Expressions,
		xbasePackage.XIfExpression_Then,
		xbasePackage.XIfExpression_Else,
		xbasePackage.XCasePart_Then,
		xbasePackage.XAbstractWhileExpression_Body
	}

	@Inject extension JavammNodeModelUtil
	@Inject extension JavammModelUtil
	
	override protected getEPackages() {
		val result = new ArrayList<EPackage>(super.getEPackages());
	    result.add(JavammPackage.eINSTANCE);
	    result.add(EPackage.Registry.INSTANCE.getEPackage("http://www.eclipse.org/xtext/xbase/Xbase"));
	    result.add(EPackage.Registry.INSTANCE.getEPackage("http://www.eclipse.org/xtext/common/JavaVMTypes"));
	    result.add(EPackage.Registry.INSTANCE.getEPackage("http://www.eclipse.org/xtext/xbase/Xtype"));
		return result;
	}

	override protected checkAssignment(XExpression expression, EStructuralFeature feature, boolean simpleAssignment) {
		if (expression instanceof XAbstractFeatureCall) {
			val assignmentFeature = expression.feature
			if (assignmentFeature instanceof JvmFormalParameter) {
				// all parameters are considered NOT final
				return;
			}
		}
		
		super.checkAssignment(expression, feature, simpleAssignment)
	}

	/**
	 * In case of an additional variable declaration we must use the container of
	 * the containing variable declaration, otherwise additional variables will always be
	 * detected as unused
	 */
	override protected isLocallyUsed(EObject target, EObject containerToFindUsage) {
		if (target instanceof JavammAdditionalXVariableDeclaration) {
			return super.isLocallyUsed(target, containerToFindUsage.eContainer)
		}
		return super.isLocallyUsed(target, containerToFindUsage)
	}

	@Check
	def void checkDuplicateMethods(JavammProgram p) {
		val map = duplicatesMultimap
		
		for (d : p.javammMethods) {
			map.put(d.name, d)
		}
		
		for (entry : map.asMap.entrySet) {
			val duplicates = entry.value
			if (duplicates.size > 1) {
				for (d : duplicates)
					error(
						"Duplicate definition '" +
							d.name + "'",
						d,
						javammPackage.javammMethod_Name,
						DUPLICATE_METHOD
					)
			}
		}
	}

	@Check
	def void checkContinue(JavammContinueStatement st) {
		checkBranchingStatementInternal(st, "a loop",
			XAbstractWhileExpression, XBasicForLoopExpression
		)
	}

	@Check
	def void checkBreak(JavammBreakStatement st) {
		checkBranchingStatementInternal(st, "a loop or a switch",
			XAbstractWhileExpression, XBasicForLoopExpression,
			XSwitchExpression
		)
	}

	def private checkBranchingStatementInternal(JavammBranchingStatement st, String errorDetails, Class<? extends EObject>... validContainers) {
		val container = Wrapper.wrap(st.eContainer)
		while (!((container.get instanceof JavammMethod) || (container.get instanceof Main))) {
			if (validContainers.exists[c | c.isInstance(container.get)]) {
				return;
			}
			container.set(container.get.eContainer)
		}
		error(
			st.instruction + " cannot be used outside of " + errorDetails,
			st, null, INVALID_BRANCHING_STATEMENT
		)
	}

	@Check
	def checkMissingSemicolon(XExpression e) {
		if (e.hasToBeCheckedForMissingSemicolon) {
			checkMissingSemicolonInternal(e)
		}
	}

	@Check
	def checkMissingSemicolon(XImportDeclaration e) {
		checkMissingSemicolonInternal(e)
	}

	def private checkMissingSemicolonInternal(EObject e) {
		if (!e.hasSemicolon) {
			error(
				'Syntax error, insert ";" to complete Statement',
				e, null, MISSING_SEMICOLON
			)
		}
	}

	def private hasToBeCheckedForMissingSemicolon(XExpression e) {
		val expClass = e.class
		val containingFeature = e.eContainingFeature
		semicolonStatements.exists[c | 
			c.isAssignableFrom(expClass) &&
			featuresForRequiredSemicolon.exists[f | f == containingFeature]
		]		
	}

	@Check
	def checkMissingParentheses(XFeatureCall call) {
		checkMissingParenthesesInternal(call, call.isExplicitOperationCall)
	}

	@Check
	def checkMissingParentheses(XMemberFeatureCall call) {
		checkMissingParenthesesInternal(call, call.isExplicitOperationCall)
	}

	@Check
	def checkArrayConstructor(JavammArrayConstructorCall cons) {
		
		val arrayLiteral = cons.arrayLiteral
		val dimensionExpressions = cons.indexes
		
		if (dimensionExpressions.empty && arrayLiteral == null) {
			error(
				"Constructor must provide either dimension expressions or an array initializer",
				cons, null,
				ARRAY_CONSTRUCTOR_EITHER_DIMENSION_EXPRESSION_OR_INITIALIZER
			)
		} else if (!dimensionExpressions.empty && arrayLiteral != null) {
			error(
				"Cannot define dimension expressions when an array initializer is provided",
				cons, null,
				ARRAY_CONSTRUCTOR_BOTH_DIMENSION_EXPRESSION_AND_INITIALIZER
			)
		} else {
			val dimensionsAndIndexes = cons.arrayDimensionIndexAssociations
			var foundEmptyDimension = false
			for (d : dimensionsAndIndexes) {
				if (d == null) {
					foundEmptyDimension = true
				} else if (foundEmptyDimension) {
					error(
						"Cannot specify an array dimension after an empty dimension",
						d, null,
						ARRAY_CONSTRUCTOR_DIMENSION_EXPRESSION_AFTER_EMPTY_DIMENSION
					)
					return
				}
			}
		}
	}

	def private checkMissingParenthesesInternal(XAbstractFeatureCall call, boolean explicitOpCall) {
		// length for arrays is OK without parentheses
		if (call.feature instanceof JvmOperation && 
			!explicitOpCall &&
			call.feature.simpleName != JavammOperatorMapping.ARRAY_LENGTH
		) {
			error(
				'Syntax error, insert "()" to complete method call',
				call, xbasePackage.XAbstractFeatureCall_Feature, MISSING_PARENTHESES
			)
		}
	}
	
	def private <K, T> duplicatesMultimap() {
		return Multimaps2.<K, T> newLinkedHashListMultimap();
	}
}
