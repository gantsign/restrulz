/*
 * Copyright 2016 GantSign Ltd. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.gantsign.restrulz.validation

import com.gantsign.restrulz.restdsl.ClassType
import com.gantsign.restrulz.restdsl.PathParam
import com.gantsign.restrulz.restdsl.PathScope
import com.gantsign.restrulz.restdsl.Property
import com.gantsign.restrulz.restdsl.RequestHandler
import com.gantsign.restrulz.restdsl.Response
import com.gantsign.restrulz.restdsl.RestdslPackage
import com.gantsign.restrulz.restdsl.SimpleType
import com.gantsign.restrulz.restdsl.Specification
import com.gantsign.restrulz.restdsl.StringLengthRange
import com.gantsign.restrulz.restdsl.StringRestriction
import java.util.regex.Pattern
import java.util.regex.PatternSyntaxException
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtext.validation.Check

/**
 * This class contains custom validation rules.
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class RestdslValidator extends AbstractRestdslValidator {

	public static val INVALID_NAME_UPPER_CASE = 'invalidNameUpperCase'
	public static val INVALID_NAME_ILLEGAL_CHARS = 'invalidNameIllegalChars'
	public static val INVALID_NAME_HYPHEN_PREFIX = 'invalidNameHyphenPrefix'
	public static val INVALID_NAME_HYPHEN_SUFFIX = 'invalidNameHyphenSuffix'
	public static val INVALID_NAME_HYPHEN_RUN = 'invalidNameHyphenRun'
	public static val INVALID_NAME_DIGIT_POSITION = 'invalidNameDigitPosition'
	public static val INVALID_STRING_TYPE_PATTERN = 'invalidStringTypePattern';
	public static val INVALID_STRING_TYPE_BLANK_PATTERN = 'invalidStringTypeBlankPattern';
	public static val INVALID_STRING_TYPE_MIN_LENGTH = 'invalidStringTypeMinLengh';
	public static val INVALID_STRING_TYPE_MAX_LENGTH = 'invalidStringTypeMaxLength';
	private static val UPPERCASE = Pattern.compile("\\p{Upper}")
	private static val SUPPORTED_CHARS = Pattern.compile("[\\p{Alnum}\\-]")
	private static val ILLEGAL_DIGIT_POSITION = Pattern.compile("[\\p{Digit}][\\p{Alpha}\\-]+$")

	private def hasUpperCase(String name) {
		return UPPERCASE.matcher(name).find
	}

	private def unsupportedChars(String name) {
		return SUPPORTED_CHARS.matcher(name).replaceAll("")
	}

	private def hasIllegalDigitPosition(String name) {
		return ILLEGAL_DIGIT_POSITION.matcher(name).find
	}

	private def hasRunOfHyphens(String name) {
		return name.contains("--")
	}

	def validateName(String name, EStructuralFeature feature) {
		if (name.hasUpperCase()) {
			error('name: must be lower case',
					feature,
					INVALID_NAME_UPPER_CASE)
		}
		val unsupportedChars = name.unsupportedChars
		if (!"".equals(unsupportedChars)) {
			error('name: contains illegal character(s): ' + unsupportedChars,
					feature,
					INVALID_NAME_ILLEGAL_CHARS)
		}
		if (name.startsWith("-")) {
			error('name: must start with a letter',
					feature,
					INVALID_NAME_HYPHEN_PREFIX)
		}
		if (name.endsWith("-")) {
			error('name: must end with a letter or a digit',
					feature,
					INVALID_NAME_HYPHEN_SUFFIX)
		}
		if (name.hasRunOfHyphens) {
			error('name: hyphens must not be immediately followed by another hyphen',
					feature,
					INVALID_NAME_HYPHEN_RUN)
		}
		if (name.hasIllegalDigitPosition) {
			error('name: numeric digits are only permitted as a suffix to the name',
					feature,
					INVALID_NAME_DIGIT_POSITION)
		}
	}

	@Check
	def validateSpecificationName(Specification spec) {
		validateName(spec.name, RestdslPackage.Literals.SPECIFICATION__NAME)
	}

	def validateTypeName(String name) {
		validateName(name, RestdslPackage.Literals.TYPE__NAME)
	}

	@Check
	def validateSimpleTypeName(SimpleType type) {
		validateTypeName(type.name)
	}

	@Check
	def validateClassTypeName(ClassType type) {
		validateTypeName(type.name)
	}

	@Check
	def validatePropertyName(Property property) {
		validateName(property.name, RestdslPackage.Literals.PROPERTY__NAME)
	}

	@Check
	def validateResponseName(Response response) {
		validateName(response.name, RestdslPackage.Literals.RESPONSE__NAME)
	}

	@Check
	def validatePathScopeName(PathScope pathScope) {
		validateName(pathScope.name, RestdslPackage.Literals.PATH_SCOPE__NAME)
	}

	@Check
	def validatePathParamName(PathParam pathParam) {
		validateName(pathParam.name, RestdslPackage.Literals.PATH_PARAM__NAME)
	}

	@Check
	def validateRequestHandelerName(RequestHandler handler) {
		validateName(handler.name, RestdslPackage.Literals.REQUEST_HANDLER__NAME)
	}

	private def permitsBlank(Pattern pattern) {
		return pattern.matcher(" ").matches || pattern.matcher("\t").matches
	}

	@Check
	def validateStringPattern(StringRestriction stringRestriction) {
		val patternString = stringRestriction.pattern
		val pattern = try {
			Pattern.compile(patternString)
		} catch (PatternSyntaxException e) {
			error('pattern: not a valid regular expression',
					RestdslPackage.Literals.STRING_RESTRICTION__PATTERN,
					INVALID_STRING_TYPE_PATTERN)
			return;
		}
		if (pattern.permitsBlank) {
			error('pattern: must not permit blank strings',
					RestdslPackage.Literals.STRING_RESTRICTION__PATTERN,
					INVALID_STRING_TYPE_BLANK_PATTERN)
		}
	}

	@Check
	def validateStringLengthRange(StringLengthRange range) {
		if (range.start < 1) {
			error('min-length: must be at least 1',
					RestdslPackage.Literals.STRING_LENGTH_RANGE__START,
					INVALID_STRING_TYPE_MIN_LENGTH)
		}
		if (range.end < range.start) {
			error('max-length: must be greater than or equal to min-length',
					RestdslPackage.Literals.STRING_LENGTH_RANGE__END,
					INVALID_STRING_TYPE_MAX_LENGTH)
		}
	}
}
