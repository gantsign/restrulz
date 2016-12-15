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
/*
 * generated by Xtext 2.10.0
 */
package com.gantsign.restrulz.web

import com.gantsign.restrulz.RestdslRuntimeModule
import com.gantsign.restrulz.RestdslStandaloneSetup
import com.google.inject.Guice
import com.google.inject.Injector
import com.google.inject.Provider
import com.google.inject.util.Modules
import java.util.concurrent.ExecutorService
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

/**
 * Initialization support for running Xtext languages in web applications.
 */
@FinalFieldsConstructor
class RestdslWebSetup extends RestdslStandaloneSetup {
	
	val Provider<ExecutorService> executorServiceProvider;
	
	override Injector createInjector() {
		val runtimeModule = new RestdslRuntimeModule()
		val webModule = new RestdslWebModule(executorServiceProvider)
		return Guice.createInjector(Modules.override(runtimeModule).with(webModule))
	}
	
}
