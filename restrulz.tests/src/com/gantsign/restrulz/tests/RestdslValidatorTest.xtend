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
package com.gantsign.restrulz.tests

import com.gantsign.restrulz.restdsl.RestdslPackage
import com.gantsign.restrulz.restdsl.Specification
import com.google.inject.Inject
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.eclipse.xtext.junit4.validation.ValidationTestHelper
import org.eclipse.xtext.xbase.lib.Procedures.Procedure3
import org.junit.Test
import org.junit.runner.RunWith

import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_NAME_DIGIT_POSITION
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_NAME_HYPHEN_PREFIX
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_NAME_HYPHEN_RUN
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_NAME_HYPHEN_SUFFIX
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_NAME_ILLEGAL_CHARS
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_NAME_UPPER_CASE

@RunWith(XtextRunner)
@InjectWith(RestdslInjectorProvider)
class RestdslValidatorTest {

	@Inject extension ParseHelper<Specification>
	@Inject extension ValidationTestHelper

	def void validateName(Procedure3<String, String, String> assertionTemplate) {
		assertionTemplate.apply("TEST", INVALID_NAME_UPPER_CASE, "name: must be lower case")
		assertionTemplate.apply("a_$a", INVALID_NAME_ILLEGAL_CHARS, "name: contains illegal character(s): _$")
		assertionTemplate.apply("-est", INVALID_NAME_HYPHEN_PREFIX, "name: must start with a letter")
		assertionTemplate.apply("t--t", INVALID_NAME_HYPHEN_RUN, "name: hyphens must not be immediately followed by another hyphen")
		assertionTemplate.apply("tes-", INVALID_NAME_HYPHEN_SUFFIX, "name: must end with a letter or a digit")
		assertionTemplate.apply("t0st", INVALID_NAME_DIGIT_POSITION, "name: numeric digits are only permitted as a suffix to the name")
	}

	@Test
	def void validateSpecificationName() {
		validateName([String name, String code, String message|
			val spec = '''
				specification «name» {}
			'''.parse

			spec.assertError(RestdslPackage.Literals.SPECIFICATION, code, 14, 4, message)
		])
	}

	@Test
	def void validateSimpleTypeName() {
		validateName([String name, String code, String message|
			val spec = '''
				specification people {
				    type «name» : string ^[\p{Alpha}']$ length [1..100]
				}
			'''.parse

			spec.assertError(RestdslPackage.Literals.SIMPLE_TYPE, code, 32, 4, message)
		])
	}

	@Test
	def void validateClassTypeName() {
		validateName([String name, String code, String message|
			val spec = '''
				specification people {
				    class «name» {}
				}
			'''.parse

			spec.assertError(RestdslPackage.Literals.CLASS_TYPE, code, 33, 4, message)
		])
	}

	@Test
	def void validatePropertyName() {
		validateName([String name, String code, String message|
			val spec = '''
				specification people {
				    class person {
				        «name»
				    }
				}
			'''.parse

			spec.assertError(RestdslPackage.Literals.PROPERTY, code, 50, 4, message)
		])
	}

	@Test
	def void validateResponseName() {
		validateName([String name, String code, String message|
			val spec = '''
				specification people {
				    class person {}

				    response «name» ok person
				}
			'''.parse

			spec.assertError(RestdslPackage.Literals.RESPONSE, code, 57, 4, message)
		])
	}

	@Test
	def void validatePathScopeName() {
		validateName([String name, String code, String message|
			val spec = '''
				specification people {
				    path /person : «name» {}
				}
			'''.parse

			spec.assertError(RestdslPackage.Literals.PATH_SCOPE, code, 42, 4, message)
		])
	}

	@Test
	def void validatePathParamName() {
		validateName([String name, String code, String message|
			val spec = '''
				specification people {
				    path /person/{«name»} : person-ws {}
				}
			'''.parse

			spec.assertError(RestdslPackage.Literals.PATH_PARAM, code, 41, 4, message)
		])
	}

	@Test
	def void validateRequestHandlerName() {
		validateName([String name, String code, String message|
			val spec = '''
				specification people {
				    class person {}

				    response get-person-success : ok person

				    path /person : person-ws {
				        get -> «name»() : get-person-success
				    }
				}
			'''.parse

			spec.assertError(RestdslPackage.Literals.REQUEST_HANDLER, code, 135, 4, message)
		])
	}

	@Test
	def void validateInvalidStringPattern() {
		val spec = '''
				specification people {
				    type name : string ^[\p{Invalid}']$ length [1..100]
				}
			'''.parse

		spec.assertError(RestdslPackage.Literals.STRING_RESTRICTION,
				"invalidStringTypePattern", 46, 16, "pattern: not a valid regular expression")
	}

	@Test
	def void validateInvalidStringBlankSpace() {
		val spec = '''
				specification people {
				    type name : string ^ $ length [1..100]
				}
			'''.parse

		spec.assertError(RestdslPackage.Literals.STRING_RESTRICTION,
				"invalidStringTypeBlankPattern", 46, 3, "pattern: must not permit blank strings")
	}

	@Test
	def void validateInvalidStringTab() {
		val spec = '''
				specification people {
				    type name : string ^	$ length [1..100]
				}
			'''.parse

		spec.assertError(RestdslPackage.Literals.STRING_RESTRICTION,
				"invalidStringTypeBlankPattern", 46, 3, "pattern: must not permit blank strings")
	}

	@Test
	def void validateInvalidStringMinLength() {
		val spec = '''
				specification people {
				    type name : string ^[\p{Alpha}']$ length [0..100]
				}
			'''.parse

		spec.assertError(RestdslPackage.Literals.STRING_LENGTH_RANGE,
				"invalidStringTypeMinLengh", 69, 1, "min-length: must be at least 1")
	}

	@Test
	def void validateInvalidStringMaxLength() {
		val spec = '''
				specification people {
				    type name : string ^[\p{Alpha}']$ length [10..9]
				}
			'''.parse

		spec.assertError(RestdslPackage.Literals.STRING_LENGTH_RANGE, "invalidStringTypeMaxLength",
				73, 1, "max-length: must be greater than or equal to min-length")
	}
}
