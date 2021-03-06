/*
 * Copyright 2016-2017 GantSign Ltd. All Rights Reserved.
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
import com.google.inject.Provider
import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.eclipse.xtext.junit4.validation.ValidationTestHelper
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.xbase.lib.Procedures.Procedure3
import org.junit.Test
import org.junit.runner.RunWith

import static com.gantsign.restrulz.validation.RestdslValidator.BAD_HANDLER_MISSING_ERROR_RESPONSE
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_HANDLER_DUPLICATE_METHOD
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_HANDLER_DUPLICATE_RESPONSE
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_HANDLER_DUPLICATE_RESPONSE_STATUS
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_INTEGER_RANGE
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_NAME_DIGIT_POSITION
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_NAME_DUPLICATE
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_NAME_HYPHEN_PREFIX
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_NAME_HYPHEN_RUN
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_NAME_HYPHEN_SUFFIX
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_NAME_ILLEGAL_CHARS
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_NAME_UPPER_CASE
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_PATH_DUPLICATE
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_PROPERTY_EMPTY
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_PROPERTY_NULL
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_STRING_TYPE_MAX_LENGTH
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_STRING_TYPE_MIN_LENGTH
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_STRING_TYPE_PATTERN
import static com.gantsign.restrulz.validation.RestdslValidator.INVALID_SPECIFICATION_NAME_FILE_MISMATCH

@RunWith(XtextRunner)
@InjectWith(RestdslInjectorProvider)
class RestdslValidatorTest {

	@Inject extension ParseHelper<Specification>
	@Inject extension ValidationTestHelper

	@Inject
	private Provider<XtextResourceSet> resourceSetProvider;

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
	def void validateSpecificationNameAgainstFile() {
		val spec = '''
				specification person {}
			'''.parse(URI.createURI("unmatched.rrdl"), resourceSetProvider.get)

		spec.assertError(RestdslPackage.Literals.SPECIFICATION,
				INVALID_SPECIFICATION_NAME_FILE_MISMATCH, 14, 6,
				"name: must match file name (i.e. unmatched)")
	}

	@Test
	def void validateSimpleTypeName() {
		validateName([String name, String code, String message|
			val spec = '''
				specification people {
					type «name» : string ^[\p{Alpha}']$ length [1..100]
				}
			'''.parse

			spec.assertError(RestdslPackage.Literals.SIMPLE_TYPE, code, 29, 4, message)
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

			spec.assertError(RestdslPackage.Literals.CLASS_TYPE, code, 30, 4, message)
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

			spec.assertError(RestdslPackage.Literals.PROPERTY, code, 41, 4, message)
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

			spec.assertError(RestdslPackage.Literals.RESPONSE, code, 51, 4, message)
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

			spec.assertError(RestdslPackage.Literals.PATH_SCOPE, code, 39, 4, message)
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

			spec.assertError(RestdslPackage.Literals.PATH_PARAM, code, 38, 4, message)
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

			spec.assertError(RestdslPackage.Literals.REQUEST_HANDLER, code, 120, 4, message)
		])
	}

	@Test
	def void validateMethodParameterName() {
		validateName([String name, String code, String message|
			val spec = '''
				specification people {
					class person {}

					response get-person-success : ok person

					path /person : person-ws {
						get -> get-person(«name» = *person) : get-person-success
					}
				}
			'''.parse

			spec.assertError(RestdslPackage.Literals.METHOD_PARAMETER, code, 131, 4, message)
		])
	}

	@Test
	def void validateInvalidStringPattern() {
		val spec = '''
			specification people {
				type name : string ^[\p{Invalid}']$ length [1..100]
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.STRING_TYPE,
				INVALID_STRING_TYPE_PATTERN, 43, 16, "pattern: not a valid regular expression")
	}

	@Test
	def void validateInvalidStringMinLength() {
		val spec = '''
			specification people {
				type name : string ^[\p{Alpha}']$ length [0..100]
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.STRING_TYPE,
				INVALID_STRING_TYPE_MIN_LENGTH, 66, 1, "min-length: must be at least 1")
	}

	@Test
	def void validateInvalidStringMaxLength() {
		val spec = '''
			specification people {
				type name : string ^[\p{Alpha}']$ length [10..9]
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.STRING_TYPE, INVALID_STRING_TYPE_MAX_LENGTH,
				70, 1, "max-length: must be greater than or equal to min-length")
	}

	@Test
	def void validateInvalidIntegerMaximum() {
		val spec = '''
			specification people {
				type age : int [10..9]
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.INTEGER_TYPE, INVALID_INTEGER_RANGE,
				44, 1, "maximum: must be greater than or equal to minimum")
	}

	@Test
	def void validateDuplicateSimpleTypes() {
		val spec = '''
			specification people {
				type name : string ^[\p{Alpha}']$ length [1..100]
				type name : string ^[\p{Alpha}']$ length [1..100]
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.SIMPLE_TYPE, INVALID_NAME_DUPLICATE,
				29, 4, "name: type/class names must be unique")
		spec.assertError(RestdslPackage.Literals.SIMPLE_TYPE, INVALID_NAME_DUPLICATE,
				80, 4, "name: type/class names must be unique")
	}

	@Test
	def void validateDuplicateClassTypes() {
		val spec = '''
			specification people {
				class person {}
				class person {}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.CLASS_TYPE, INVALID_NAME_DUPLICATE,
				30, 6, "name: type/class names must be unique")
		spec.assertError(RestdslPackage.Literals.CLASS_TYPE, INVALID_NAME_DUPLICATE,
				47, 6, "name: type/class names must be unique")
	}

	@Test
	def void validateDuplicateMixedTypes() {
		val spec = '''
			specification people {
				type name : string ^[\p{Alpha}']$ length [1..100]
				class name {}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.SIMPLE_TYPE, INVALID_NAME_DUPLICATE,
				29, 4, "name: type/class names must be unique")
		spec.assertError(RestdslPackage.Literals.CLASS_TYPE, INVALID_NAME_DUPLICATE,
				81, 4, "name: type/class names must be unique")
	}

	@Test
	def void validateDuplicatePropertyNames() {
		val spec = '''
			specification people {
				class person {
					name
					name
				}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.PROPERTY, INVALID_NAME_DUPLICATE,
				41, 4, "name: property names must be unique")
		spec.assertError(RestdslPackage.Literals.PROPERTY, INVALID_NAME_DUPLICATE,
				48, 4, "name: property names must be unique")
	}

	@Test
	def void validateDuplicateResponseNames() {
		val spec = '''
			specification people {
				class person {}
				response get-uperson : ok person
				response get-uperson : ok person
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.RESPONSE, INVALID_NAME_DUPLICATE,
				50, 11, "name: response names must be unique")
		spec.assertError(RestdslPackage.Literals.RESPONSE, INVALID_NAME_DUPLICATE,
				84, 11, "name: response names must be unique")
	}

	@Test
	def void validateDuplicatePathScopeNames() {
		val spec = '''
			specification people {
				path /path1 : person-ws {}
				path /path2 : person-ws {}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.PATH_SCOPE, INVALID_NAME_DUPLICATE,
				38, 9, "name: path names must be unique")
		spec.assertError(RestdslPackage.Literals.PATH_SCOPE, INVALID_NAME_DUPLICATE,
				66, 9, "name: path names must be unique")
	}

	@Test
	def void validateDuplicatePathParamNames() {
		val spec = '''
			specification people {
				path /{id}/{id} : person-ws {}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.PATH_PARAM, INVALID_NAME_DUPLICATE,
				31, 2, "name: path parameter names must be unique")
		spec.assertError(RestdslPackage.Literals.PATH_PARAM, INVALID_NAME_DUPLICATE,
				36, 2, "name: path parameter names must be unique")
	}

	@Test
	def void validateDuplicateSubPathParamNames() {
		val spec = '''
			specification people {
				path /{id} : person-ws {
					path /{id} {}
				}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.PATH_PARAM, INVALID_NAME_DUPLICATE,
				31, 2, "name: path parameter names must be unique")
		spec.assertError(RestdslPackage.Literals.PATH_PARAM, INVALID_NAME_DUPLICATE,
				58, 2, "name: path parameter names must be unique")
	}

	@Test
	def void validateDuplicateRequestHandler() {
		val spec = '''
			specification people {
				class person {}
				response get-person-success : ok person
				path /person : person-ws {
					get -> get-person() : get-person-success
					put -> get-person() : get-person-success
				}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.REQUEST_HANDLER, INVALID_NAME_DUPLICATE,
				118, 10, "name: request handler names must be unique")
		spec.assertError(RestdslPackage.Literals.REQUEST_HANDLER, INVALID_NAME_DUPLICATE,
				161, 10, "name: request handler names must be unique")
	}

	@Test
	def void validateDuplicateRequestMethod() {
		val spec = '''
			specification people {
				class person {}
				response get-person-success : ok person
				path /person : person-ws {
					get -> get-person() : get-person-success
					get -> get-person2() : get-person-success
				}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.REQUEST_HANDLER, INVALID_HANDLER_DUPLICATE_METHOD,
				111, 3, "method: each HTTP method can only have one handler")
		spec.assertError(RestdslPackage.Literals.REQUEST_HANDLER, INVALID_HANDLER_DUPLICATE_METHOD,
				154, 3, "method: each HTTP method can only have one handler")
	}

	@Test
	def void validateDuplicateParamNames() {
		val spec = '''
			specification people {
				class person {}
				response get-person-success : ok person
				path /person/{id} : person-ws {
					get -> get-person(person = /id, person = *person) : get-person-success
				}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.METHOD_PARAMETER, INVALID_NAME_DUPLICATE,
				134, 6, "name: parameter name must be unique")
		spec.assertError(RestdslPackage.Literals.METHOD_PARAMETER, INVALID_NAME_DUPLICATE,
				148, 6, "name: parameter name must be unique")
	}

	@Test
	def void validateDuplicateResponseMappings() {
		val spec = '''
			specification people {
				class person {}
				response get-person-success : ok person
				path /person/{id} : person-ws {
					get -> get-person() : get-person-success | get-person-success
				}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.RESPONSE_REF, INVALID_HANDLER_DUPLICATE_RESPONSE,
				138, 18, "duplicate response mapping")
		spec.assertError(RestdslPackage.Literals.RESPONSE_REF, INVALID_HANDLER_DUPLICATE_RESPONSE,
				159, 18, "duplicate response mapping")
	}

	@Test
	def void validateDuplicateResponseStatusMappings() {
		val spec = '''
			specification people {
				class person {}
				response get-person-success : ok person
				response ok-person-success : ok person
				path /person/{id} : person-ws {
					get -> get-person() : get-person-success | ok-person-success
				}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.RESPONSE_REF,
				INVALID_HANDLER_DUPLICATE_RESPONSE_STATUS,
				178, 18, "duplicate mapping for HTTP status code 200 (ok)")
		spec.assertError(RestdslPackage.Literals.RESPONSE_REF,
				INVALID_HANDLER_DUPLICATE_RESPONSE_STATUS,
				199, 17, "duplicate mapping for HTTP status code 200 (ok)")
	}

	@Test
	def void validateMissingErrorMappingWarning() {
		val spec = '''
			specification people {
				class person {}
				response get-person-success : ok person
				path /person/{id} : person-ws {
					get -> get-person() : get-person-success
				}
			}
		'''.parse

		spec.assertWarning(RestdslPackage.Literals.REQUEST_HANDLER,
				BAD_HANDLER_MISSING_ERROR_RESPONSE,
				138, 18, "no mapping for HTTP 500 (internal-server-error)")
	}

	@Test
	def void validateDuplicatePath() {
		val spec = '''
			specification people {
				path /person/{id} : person-ws {}
				path /person/{id} : person-ws2 {}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.PATH_SCOPE, INVALID_PATH_DUPLICATE,
				29, 12, "path must be unique")
		spec.assertError(RestdslPackage.Literals.PATH_SCOPE, INVALID_PATH_DUPLICATE,
				63, 12, "path must be unique")
	}

	@Test
	def void validateNullString() {
		val spec = '''
			specification people {
				type name : string ^[\p{Alpha}']$ length [1..100]
				class person {
					first-name: name | null
				}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.PROPERTY, INVALID_PROPERTY_NULL,
				111, 4, "only integer and class types are allowed to be null")
	}

	@Test
	def void validateEmptyInteger() {
		val spec = '''
			specification people {
				type age : int [0..150]
				class person {
					age: age | empty
				}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.PROPERTY, INVALID_PROPERTY_EMPTY,
				77, 5, "only string types are allowed to be empty")
	}

	@Test
	def void validateEmptyClass() {
		val spec = '''
			specification people {
				class address {}
				class person {
					address: address | empty
				}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.PROPERTY, INVALID_PROPERTY_EMPTY,
				78, 5, "only string types are allowed to be empty")
	}

	@Test
	def void validateEmptyBoolean() {
		val spec = '''
			specification people {
				class person {
					active: boolean | empty
				}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.PROPERTY, INVALID_PROPERTY_EMPTY,
				59, 5, "only string types are allowed to be empty")
	}

	@Test
	def void validateNullBoolean() {
		val spec = '''
			specification people {
				class person {
					active: boolean | null
				}
			}
		'''.parse

		spec.assertError(RestdslPackage.Literals.PROPERTY, INVALID_PROPERTY_NULL,
				59, 4, "only integer and class types are allowed to be null")
	}
}
