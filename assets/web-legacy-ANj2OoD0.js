!function(){function e(e){if(null!=e){var t=e["function"==typeof Symbol&&Symbol.iterator||"@@iterator"],r=0;if(t)return t.call(e);if("function"==typeof e.next)return e;if(!isNaN(e.length))return{next:function(){return e&&r>=e.length&&(e=void 0),{value:e&&e[r++],done:!e}}}}throw new TypeError(typeof e+" is not iterable")}function t(e,t){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);t&&(n=n.filter(function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable})),r.push.apply(r,n)}return r}function r(e){for(var r=1;r<arguments.length;r++){var a=null!=arguments[r]?arguments[r]:{};r%2?t(Object(a),!0).forEach(function(t){n(e,t,a[t])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(a)):t(Object(a)).forEach(function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(a,t))})}return e}function n(e,t,r){return(t=function(e){var t=function(e,t){if("object"!=typeof e||!e)return e;var r;if("undefined"!=typeof Symbol&&void 0!==(r=e[Symbol.toPrimitive])){var n=r.call(e,t||"default");if("object"!=typeof n)return n;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===t?String:Number)(e)}(e,"string");return"symbol"==typeof t?t:t+""}(t))in e?Object.defineProperty(e,t,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[t]=r,e}function a(){/*! regenerator-runtime -- Copyright (c) 2014-present, Facebook, Inc. -- license (MIT): https://github.com/babel/babel/blob/main/packages/babel-helpers/LICENSE */var e,t,r="function"==typeof Symbol?Symbol:{},n=r.iterator||"@@iterator",o=r.toStringTag||"@@toStringTag";function s(r,n,a,o){var s=n&&n.prototype instanceof u?n:u,f=Object.create(s.prototype);return i(f,"_invoke",function(r,n,a){var i,o,s,u=0,f=a||[],l=!1,p={p:0,n:0,v:e,a:d,f:d.bind(e,4),d:function(t,r){return i=t,o=0,s=e,p.n=r,c}};function d(r,n){for(o=r,s=n,t=0;!l&&u&&!a&&t<f.length;t++){var a,i=f[t],d=p.p,h=i[2];r>3?(a=h===n)&&(s=i[(o=i[4])?5:(o=3,3)],i[4]=i[5]=e):i[0]<=d&&((a=r<2&&d<i[1])?(o=0,p.v=n,p.n=i[1]):d<h&&(a=r<3||i[0]>n||n>h)&&(i[4]=r,i[5]=n,p.n=h,o=0))}if(a||r>1)return c;throw l=!0,n}return function(a,f,h){if(u>1)throw TypeError("Generator is already running");for(l&&1===f&&d(f,h),o=f,s=h;(t=o<2?e:s)||!l;){i||(o?(o>1&&(p.n=o<3?-1:s),d(o,s)):p.v=s);try{if(u=2,i){if(o||(a="next"),t=i[a]){if(!(t=t.call(i,s)))throw TypeError("iterator result is not an object");if(!t.done)return t;s=t.value,o<2&&(o=0)}else 1===o&&(t=i.return)&&t.call(i),o<2&&(s=TypeError("The iterator does not provide a '"+a+"' method"),o=1);i=e}else if((t=(l=p.n<0)?s:r.call(n,p))!==c)break}catch(t){i=e,o=1,s=t}finally{u=1}}return{value:t,done:l}}}(r,a,o),!0),f}var c={};function u(){}function f(){}function l(){}t=Object.getPrototypeOf;var p=[][n]?t(t([][n]())):(i(t={},n,function(){return this}),t),d=l.prototype=u.prototype=Object.create(p);function h(e){return Object.setPrototypeOf?Object.setPrototypeOf(e,l):(e.__proto__=l,i(e,o,"GeneratorFunction")),e.prototype=Object.create(d),e}return f.prototype=l,i(d,"constructor",l),i(l,"constructor",f),f.displayName="GeneratorFunction",i(l,o,"GeneratorFunction"),i(d),i(d,o,"Generator"),i(d,n,function(){return this}),i(d,"toString",function(){return"[object Generator]"}),(a=function(){return{w:s,m:h}})()}function i(e,t,r,n){var a=Object.defineProperty;try{a({},"",{})}catch(e){a=0}i=function(e,t,r,n){function o(t,r){i(e,t,function(e){return this._invoke(t,r,e)})}t?a?a(e,t,{value:r,enumerable:!n,configurable:!n,writable:!n}):e[t]=r:(o("next",0),o("throw",1),o("return",2))},i(e,t,r,n)}function o(e,t,r,n,a,i,o){try{var s=e[i](o),c=s.value}catch(e){return void r(e)}s.done?t(c):Promise.resolve(c).then(n,a)}function s(e){return function(){var t=this,r=arguments;return new Promise(function(n,a){var i=e.apply(t,r);function s(e){o(i,n,a,s,c,"next",e)}function c(e){o(i,n,a,s,c,"throw",e)}s(void 0)})}}function c(e,t){return function(e){if(Array.isArray(e))return e}(e)||function(e,t){var r=null==e?null:"undefined"!=typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=r){var n,a,i,o,s=[],c=!0,u=!1;try{if(i=(r=r.call(e)).next,0===t){if(Object(r)!==r)return;c=!1}else for(;!(c=(n=i.call(r)).done)&&(s.push(n.value),s.length!==t);c=!0);}catch(e){u=!0,a=e}finally{try{if(!c&&null!=r.return&&(o=r.return(),Object(o)!==o))return}finally{if(u)throw a}}return s}}(e,t)||f(e,t)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function u(e,t){var r="undefined"!=typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(!r){if(Array.isArray(e)||(r=f(e))||t&&e&&"number"==typeof e.length){r&&(e=r);var n=0,a=function(){};return{s:a,n:function(){return n>=e.length?{done:!0}:{done:!1,value:e[n++]}},e:function(e){throw e},f:a}}throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}var i,o=!0,s=!1;return{s:function(){r=r.call(e)},n:function(){var e=r.next();return o=e.done,e},e:function(e){s=!0,i=e},f:function(){try{o||null==r.return||r.return()}finally{if(s)throw i}}}}function f(e,t){if(e){if("string"==typeof e)return l(e,t);var r={}.toString.call(e).slice(8,-1);return"Object"===r&&e.constructor&&(r=e.constructor.name),"Map"===r||"Set"===r?Array.from(e):"Arguments"===r||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(r)?l(e,t):void 0}}function l(e,t){(null==t||t>e.length)&&(t=e.length);for(var r=0,n=Array(t);r<t;r++)n[r]=e[r];return n}System.register(["./supabase-legacy-DclnnLn2.js","./index-legacy-DiApv05v.js"],function(t,n){"use strict";var i;return{setters:[e=>{i=e.W},null],execute:function(){var n={},o=function(e){for(var t=[],r=0,n=0;n<e.length;n++){var a=e.charCodeAt(n);a<128?t[r++]=a:a<2048?(t[r++]=a>>6|192,t[r++]=63&a|128):55296==(64512&a)&&n+1<e.length&&56320==(64512&e.charCodeAt(n+1))?(a=65536+((1023&a)<<10)+(1023&e.charCodeAt(++n)),t[r++]=a>>18|240,t[r++]=a>>12&63|128,t[r++]=a>>6&63|128,t[r++]=63&a|128):(t[r++]=a>>12|224,t[r++]=a>>6&63|128,t[r++]=63&a|128)}return t},f={byteToCharMap_:null,charToByteMap_:null,byteToCharMapWebSafe_:null,charToByteMapWebSafe_:null,ENCODED_VALS_BASE:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",get ENCODED_VALS(){return this.ENCODED_VALS_BASE+"+/="},get ENCODED_VALS_WEBSAFE(){return this.ENCODED_VALS_BASE+"-_."},HAS_NATIVE_SUPPORT:"function"==typeof atob,encodeByteArray(e,t){if(!Array.isArray(e))throw Error("encodeByteArray takes an array as a parameter");this.init_();for(var r=t?this.byteToCharMapWebSafe_:this.byteToCharMap_,n=[],a=0;a<e.length;a+=3){var i=e[a],o=a+1<e.length,s=o?e[a+1]:0,c=a+2<e.length,u=c?e[a+2]:0,f=i>>2,l=(3&i)<<4|s>>4,p=(15&s)<<2|u>>6,d=63&u;c||(d=64,o||(p=64)),n.push(r[f],r[l],r[p],r[d])}return n.join("")},encodeString(e,t){return this.HAS_NATIVE_SUPPORT&&!t?btoa(e):this.encodeByteArray(o(e),t)},decodeString(e,t){return this.HAS_NATIVE_SUPPORT&&!t?atob(e):function(e){for(var t=[],r=0,n=0;r<e.length;){var a=e[r++];if(a<128)t[n++]=String.fromCharCode(a);else if(a>191&&a<224){var i=e[r++];t[n++]=String.fromCharCode((31&a)<<6|63&i)}else if(a>239&&a<365){var o=((7&a)<<18|(63&e[r++])<<12|(63&e[r++])<<6|63&e[r++])-65536;t[n++]=String.fromCharCode(55296+(o>>10)),t[n++]=String.fromCharCode(56320+(1023&o))}else{var s=e[r++],c=e[r++];t[n++]=String.fromCharCode((15&a)<<12|(63&s)<<6|63&c)}}return t.join("")}(this.decodeStringToByteArray(e,t))},decodeStringToByteArray(e,t){this.init_();for(var r=t?this.charToByteMapWebSafe_:this.charToByteMap_,n=[],a=0;a<e.length;){var i=r[e.charAt(a++)],o=a<e.length?r[e.charAt(a)]:0,s=++a<e.length?r[e.charAt(a)]:64,c=++a<e.length?r[e.charAt(a)]:64;if(++a,null==i||null==o||null==s||null==c)throw new l;var u=i<<2|o>>4;if(n.push(u),64!==s){var f=o<<4&240|s>>2;if(n.push(f),64!==c){var p=s<<6&192|c;n.push(p)}}}return n},init_(){if(!this.byteToCharMap_){this.byteToCharMap_={},this.charToByteMap_={},this.byteToCharMapWebSafe_={},this.charToByteMapWebSafe_={};for(var e=0;e<this.ENCODED_VALS.length;e++)this.byteToCharMap_[e]=this.ENCODED_VALS.charAt(e),this.charToByteMap_[this.byteToCharMap_[e]]=e,this.byteToCharMapWebSafe_[e]=this.ENCODED_VALS_WEBSAFE.charAt(e),this.charToByteMapWebSafe_[this.byteToCharMapWebSafe_[e]]=e,e>=this.ENCODED_VALS_BASE.length&&(this.charToByteMap_[this.ENCODED_VALS_WEBSAFE.charAt(e)]=e,this.charToByteMapWebSafe_[this.ENCODED_VALS.charAt(e)]=e)}}};class l extends Error{constructor(){super(...arguments),this.name="DecodeBase64StringError"}}var p=function(e){return function(e){var t=o(e);return f.encodeByteArray(t,!0)}(e).replace(/\./g,"")};
/**
             * @license
             * Copyright 2022 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
var d=()=>
/**
             * @license
             * Copyright 2022 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
function(){if("undefined"!=typeof self)return self;if("undefined"!=typeof window)return window;if("undefined"!=typeof global)return global;throw new Error("Unable to locate global object.")}().__FIREBASE_DEFAULTS__,h=()=>{if("undefined"!=typeof document){var e;try{e=document.cookie.match(/__FIREBASE_DEFAULTS__=([^;]+)/)}catch(r){return}var t=e&&function(e){try{return f.decodeString(e,!0)}catch(r){console.error("base64Decode failed: ",r)}return null}(e[1]);return t&&JSON.parse(t)}},v=()=>{try{return d()||(()=>{if("undefined"!=typeof process){var e=n.__FIREBASE_DEFAULTS__;return e?JSON.parse(e):void 0}})()||h()}catch(e){return void console.info(`Unable to get __FIREBASE_DEFAULTS__ due to: ${e}`)}},g=()=>{var e;return null===(e=v())||void 0===e?void 0:e.config};
/**
             * @license
             * Copyright 2017 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
class b{constructor(){this.reject=()=>{},this.resolve=()=>{},this.promise=new Promise((e,t)=>{this.resolve=e,this.reject=t})}wrapCallback(e){return(t,r)=>{t?this.reject(t):this.resolve(r),"function"==typeof e&&(this.promise.catch(()=>{}),1===e.length?e(t):e(t,r))}}}function m(){try{return"object"==typeof indexedDB}catch(e){return!1}}function w(){return new Promise((e,t)=>{try{var r=!0,n="validate-browser-context-for-indexeddb-analytics-module",a=self.indexedDB.open(n);a.onsuccess=()=>{a.result.close(),r||self.indexedDB.deleteDatabase(n),e(!0)},a.onupgradeneeded=()=>{r=!1},a.onerror=()=>{var e;t((null===(e=a.error)||void 0===e?void 0:e.message)||"")}}catch(i){t(i)}})}function y(){return!("undefined"==typeof navigator||!navigator.cookieEnabled)}
/**
             * @license
             * Copyright 2017 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */class k extends Error{constructor(e,t,r){super(t),this.code=e,this.customData=r,this.name="FirebaseError",Object.setPrototypeOf(this,k.prototype),Error.captureStackTrace&&Error.captureStackTrace(this,S.prototype.create)}}class S{constructor(e,t,r){this.service=e,this.serviceName=t,this.errors=r}create(e,...t){var r=t[0]||{},n=`${this.service}/${e}`,a=this.errors[e],i=a?function(e,t){try{for(var r=0,n="";r<e.length;){var a=e.indexOf("{$",r);if(-1===a){n+=e.substring(r);break}var i=e.indexOf("}",a+2);if(-1===i){n+=e.substring(r);break}var o=e.substring(a+2,i),s=t[o];n+=e.substring(r,a)+(null!=s?String(s):`<${o}?>`),r=i+1}return n}catch(c){return e}}(a,r):"Error",o=`${this.serviceName}: ${i} (${n}).`;return new k(n,o,r)}}function I(e,t){if(e===t)return!0;for(var r=Object.keys(e),n=Object.keys(t),a=0,i=r;a<i.length;a++){var o=i[a];if(!n.includes(o))return!1;var s=e[o],c=t[o];if(E(s)&&E(c)){if(!I(s,c))return!1}else if(s!==c)return!1}for(var u=0,f=n;u<f.length;u++){var l=f[u];if(!r.includes(l))return!1}return!0}function E(e){return null!==e&&"object"==typeof e}
/**
             * @license
             * Copyright 2021 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function _(e){return e&&e._delegate?e._delegate:e}class C{constructor(e,t,r){this.name=e,this.instanceFactory=t,this.type=r,this.multipleInstances=!1,this.serviceProps={},this.instantiationMode="LAZY",this.onInstanceCreated=null}setInstantiationMode(e){return this.instantiationMode=e,this}setMultipleInstances(e){return this.multipleInstances=e,this}setServiceProps(e){return this.serviceProps=e,this}setInstanceCreatedCallback(e){return this.onInstanceCreated=e,this}}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */var D,T="[DEFAULT]";
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */class O{constructor(e,t){this.name=e,this.container=t,this.component=null,this.instances=new Map,this.instancesDeferred=new Map,this.instancesOptions=new Map,this.onInitCallbacks=new Map}get(e){var t=this.normalizeInstanceIdentifier(e);if(!this.instancesDeferred.has(t)){var r=new b;if(this.instancesDeferred.set(t,r),this.isInitialized(t)||this.shouldAutoInitialize())try{var n=this.getOrInitializeService({instanceIdentifier:t});n&&r.resolve(n)}catch(a){}}return this.instancesDeferred.get(t).promise}getImmediate(e){var t,r=this.normalizeInstanceIdentifier(null==e?void 0:e.identifier),n=null!==(t=null==e?void 0:e.optional)&&void 0!==t&&t;if(!this.isInitialized(r)&&!this.shouldAutoInitialize()){if(n)return null;throw Error(`Service ${this.name} is not available`)}try{return this.getOrInitializeService({instanceIdentifier:r})}catch(a){if(n)return null;throw a}}getComponent(){return this.component}setComponent(e){if(e.name!==this.name)throw Error(`Mismatching Component ${e.name} for Provider ${this.name}.`);if(this.component)throw Error(`Component for ${this.name} has already been provided`);if(this.component=e,this.shouldAutoInitialize()){if(function(e){return"EAGER"===e.instantiationMode}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */(e))try{this.getOrInitializeService({instanceIdentifier:T})}catch(f){}var t,r=u(this.instancesDeferred.entries());try{for(r.s();!(t=r.n()).done;){var n=c(t.value,2),a=n[0],i=n[1],o=this.normalizeInstanceIdentifier(a);try{var s=this.getOrInitializeService({instanceIdentifier:o});i.resolve(s)}catch(f){}}}catch(l){r.e(l)}finally{r.f()}}}clearInstance(e=T){this.instancesDeferred.delete(e),this.instancesOptions.delete(e),this.instances.delete(e)}delete(){var e=this;return s(a().m(function t(){var r;return a().w(function(t){for(;;)switch(t.n){case 0:return r=Array.from(e.instances.values()),t.n=1,Promise.all([...r.filter(e=>"INTERNAL"in e).map(e=>e.INTERNAL.delete()),...r.filter(e=>"_delete"in e).map(e=>e._delete())]);case 1:return t.a(2)}},t)}))()}isComponentSet(){return null!=this.component}isInitialized(e=T){return this.instances.has(e)}getOptions(e=T){return this.instancesOptions.get(e)||{}}initialize(e={}){var t=e.options,r=void 0===t?{}:t,n=this.normalizeInstanceIdentifier(e.instanceIdentifier);if(this.isInitialized(n))throw Error(`${this.name}(${n}) has already been initialized`);if(!this.isComponentSet())throw Error(`Component ${this.name} has not been registered yet`);var a,i=this.getOrInitializeService({instanceIdentifier:n,options:r}),o=u(this.instancesDeferred.entries());try{for(o.s();!(a=o.n()).done;){var s=c(a.value,2),f=s[0],l=s[1];n===this.normalizeInstanceIdentifier(f)&&l.resolve(i)}}catch(p){o.e(p)}finally{o.f()}return i}onInit(e,t){var r,n=this.normalizeInstanceIdentifier(t),a=null!==(r=this.onInitCallbacks.get(n))&&void 0!==r?r:new Set;a.add(e),this.onInitCallbacks.set(n,a);var i=this.instances.get(n);return i&&e(i,n),()=>{a.delete(e)}}invokeOnInitCallbacks(e,t){var r=this.onInitCallbacks.get(t);if(r){var n,a=u(r);try{for(a.s();!(n=a.n()).done;){var i=n.value;try{i(e,t)}catch(o){}}}catch(s){a.e(s)}finally{a.f()}}}getOrInitializeService({instanceIdentifier:e,options:t={}}){var r,n=this.instances.get(e);if(!n&&this.component&&(n=this.component.instanceFactory(this.container,{instanceIdentifier:(r=e,r===T?void 0:r),options:t}),this.instances.set(e,n),this.instancesOptions.set(e,t),this.invokeOnInitCallbacks(n,e),this.component.onInstanceCreated))try{this.component.onInstanceCreated(this.container,e,n)}catch(a){}return n||null}normalizeInstanceIdentifier(e=T){return this.component?this.component.multipleInstances?e:T:e}shouldAutoInitialize(){return!!this.component&&"EXPLICIT"!==this.component.instantiationMode}}class A{constructor(e){this.name=e,this.providers=new Map}addComponent(e){var t=this.getProvider(e.name);if(t.isComponentSet())throw new Error(`Component ${e.name} has already been registered with ${this.name}`);t.setComponent(e)}addOrOverwriteComponent(e){this.getProvider(e.name).isComponentSet()&&this.providers.delete(e.name),this.addComponent(e)}getProvider(e){if(this.providers.has(e))return this.providers.get(e);var t=new O(e,this);return this.providers.set(e,t),t}getProviders(){return Array.from(this.providers.values())}}
/**
             * @license
             * Copyright 2017 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */!function(e){e[e.DEBUG=0]="DEBUG",e[e.VERBOSE=1]="VERBOSE",e[e.INFO=2]="INFO",e[e.WARN=3]="WARN",e[e.ERROR=4]="ERROR",e[e.SILENT=5]="SILENT"}(D||(D={}));var N={debug:D.DEBUG,verbose:D.VERBOSE,info:D.INFO,warn:D.WARN,error:D.ERROR,silent:D.SILENT},P=D.INFO,j={[D.DEBUG]:"log",[D.VERBOSE]:"log",[D.INFO]:"info",[D.WARN]:"warn",[D.ERROR]:"error"},R=(e,t,...r)=>{if(!(t<e.logLevel)){var n=(new Date).toISOString(),a=j[t];if(!a)throw new Error(`Attempted to log a message with an invalid logType (value: ${t})`);console[a](`[${n}]  ${e.name}:`,...r)}};var M,B;var L=new WeakMap,$=new WeakMap,x=new WeakMap,H=new WeakMap,F=new WeakMap;var K={get(e,t,r){if(e instanceof IDBTransaction){if("done"===t)return $.get(e);if("objectStoreNames"===t)return e.objectStoreNames||x.get(e);if("store"===t)return r.objectStoreNames[1]?void 0:r.objectStore(r.objectStoreNames[0])}return W(e[t])},set:(e,t,r)=>(e[t]=r,!0),has:(e,t)=>e instanceof IDBTransaction&&("done"===t||"store"===t)||t in e};function U(e){return e!==IDBDatabase.prototype.transaction||"objectStoreNames"in IDBTransaction.prototype?(B||(B=[IDBCursor.prototype.advance,IDBCursor.prototype.continue,IDBCursor.prototype.continuePrimaryKey])).includes(e)?function(...t){return e.apply(z(this),t),W(L.get(this))}:function(...t){return W(e.apply(z(this),t))}:function(t,...r){var n=e.call(z(this),t,...r);return x.set(n,t.sort?t.sort():[t]),W(n)}}function V(e){return"function"==typeof e?U(e):(e instanceof IDBTransaction&&function(e){if(!$.has(e)){var t=new Promise((t,r)=>{var n=()=>{e.removeEventListener("complete",a),e.removeEventListener("error",i),e.removeEventListener("abort",i)},a=()=>{t(),n()},i=()=>{r(e.error||new DOMException("AbortError","AbortError")),n()};e.addEventListener("complete",a),e.addEventListener("error",i),e.addEventListener("abort",i)});$.set(e,t)}}(e),t=e,(M||(M=[IDBDatabase,IDBObjectStore,IDBIndex,IDBCursor,IDBTransaction])).some(e=>t instanceof e)?new Proxy(e,K):e);var t}function W(e){if(e instanceof IDBRequest)return t=e,(r=new Promise((e,r)=>{var n=()=>{t.removeEventListener("success",a),t.removeEventListener("error",i)},a=()=>{e(W(t.result)),n()},i=()=>{r(t.error),n()};t.addEventListener("success",a),t.addEventListener("error",i)})).then(e=>{e instanceof IDBCursor&&L.set(e,t)}).catch(()=>{}),F.set(r,t),r;var t,r;if(H.has(e))return H.get(e);var n=V(e);return n!==e&&(H.set(e,n),F.set(n,e)),n}var z=e=>F.get(e);function q(e,t,{blocked:r,upgrade:n,blocking:a,terminated:i}={}){var o=indexedDB.open(e,t),s=W(o);return n&&o.addEventListener("upgradeneeded",e=>{n(W(o.result),e.oldVersion,e.newVersion,W(o.transaction),e)}),r&&o.addEventListener("blocked",e=>r(e.oldVersion,e.newVersion,e)),s.then(e=>{i&&e.addEventListener("close",()=>i()),a&&e.addEventListener("versionchange",e=>a(e.oldVersion,e.newVersion,e))}).catch(()=>{}),s}function G(e,{blocked:t}={}){var r=indexedDB.deleteDatabase(e);return t&&r.addEventListener("blocked",e=>t(e.oldVersion,e)),W(r).then(()=>{})}var J=["get","getKey","getAll","getAllKeys","count"],Q=["put","add","delete","clear"],Y=new Map;function Z(e,t){if(e instanceof IDBDatabase&&!(t in e)&&"string"==typeof t){if(Y.get(t))return Y.get(t);var r=t.replace(/FromIndex$/,""),n=t!==r,i=Q.includes(r);if(r in(n?IDBIndex:IDBObjectStore).prototype&&(i||J.includes(r))){var o=function(){var e=s(a().m(function e(t,...o){var s,c;return a().w(function(e){for(;;)switch(e.n){case 0:return s=this.transaction(t,i?"readwrite":"readonly"),c=s.store,n&&(c=c.index(o.shift())),e.n=1,Promise.all([c[r](...o),i&&s.done]);case 1:return e.a(2,e.v[0])}},e,this)}));return function(t){return e.apply(this,arguments)}}();return Y.set(t,o),o}}}K=(e=>r(r({},e),{},{get:(t,r,n)=>Z(t,r)||e.get(t,r,n),has:(t,r)=>!!Z(t,r)||e.has(t,r)}))(K);
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
class X{constructor(e){this.container=e}getPlatformInfoString(){return this.container.getProviders().map(e=>{if(function(e){var t=e.getComponent();return"VERSION"===(null==t?void 0:t.type)}(e)){var t=e.getImmediate();return`${t.library}/${t.version}`}return null}).filter(e=>e).join(" ")}}var ee="@firebase/app",te="0.16.2",re=new class{constructor(e){this.name=e,this._logLevel=P,this._logHandler=R,this._userLogHandler=null}get logLevel(){return this._logLevel}set logLevel(e){if(!(e in D))throw new TypeError(`Invalid value "${e}" assigned to \`logLevel\``);this._logLevel=e}setLogLevel(e){this._logLevel="string"==typeof e?N[e]:e}get logHandler(){return this._logHandler}set logHandler(e){if("function"!=typeof e)throw new TypeError("Value assigned to `logHandler` must be a function");this._logHandler=e}get userLogHandler(){return this._userLogHandler}set userLogHandler(e){this._userLogHandler=e}debug(...e){this._userLogHandler&&this._userLogHandler(this,D.DEBUG,...e),this._logHandler(this,D.DEBUG,...e)}log(...e){this._userLogHandler&&this._userLogHandler(this,D.VERBOSE,...e),this._logHandler(this,D.VERBOSE,...e)}info(...e){this._userLogHandler&&this._userLogHandler(this,D.INFO,...e),this._logHandler(this,D.INFO,...e)}warn(...e){this._userLogHandler&&this._userLogHandler(this,D.WARN,...e),this._logHandler(this,D.WARN,...e)}error(...e){this._userLogHandler&&this._userLogHandler(this,D.ERROR,...e),this._logHandler(this,D.ERROR,...e)}}("@firebase/app"),ne="@firebase/app-compat",ae="@firebase/analytics-compat",ie="@firebase/analytics",oe="@firebase/app-check-compat",se="@firebase/app-check",ce="@firebase/auth",ue="@firebase/auth-compat",fe="@firebase/database",le="@firebase/data-connect",pe="@firebase/database-compat",de="@firebase/functions",he="@firebase/functions-compat",ve="@firebase/installations",ge="@firebase/installations-compat",be="@firebase/messaging",me="@firebase/messaging-compat",we="@firebase/performance",ye="@firebase/performance-compat",ke="@firebase/remote-config",Se="@firebase/remote-config-compat",Ie="@firebase/storage",Ee="@firebase/storage-compat",_e="@firebase/firestore",Ce="@firebase/ai",De="@firebase/firestore-compat",Te="firebase",Oe="[DEFAULT]",Ae={[ee]:"fire-core",[ne]:"fire-core-compat",[ie]:"fire-analytics",[ae]:"fire-analytics-compat",[se]:"fire-app-check",[oe]:"fire-app-check-compat",[ce]:"fire-auth",[ue]:"fire-auth-compat",[fe]:"fire-rtdb",[le]:"fire-data-connect",[pe]:"fire-rtdb-compat",[de]:"fire-fn",[he]:"fire-fn-compat",[ve]:"fire-iid",[ge]:"fire-iid-compat",[be]:"fire-fcm",[me]:"fire-fcm-compat",[we]:"fire-perf",[ye]:"fire-perf-compat",[ke]:"fire-rc",[Se]:"fire-rc-compat",[Ie]:"fire-gcs",[Ee]:"fire-gcs-compat",[_e]:"fire-fst",[De]:"fire-fst-compat",[Ce]:"fire-vertex","fire-js":"fire-js",[Te]:"fire-js-all"},Ne=new Map,Pe=new Map,je=new Map;function Re(e,t){try{e.container.addComponent(t)}catch(r){re.debug(`Component ${t.name} failed to register with FirebaseApp ${e.name}`,r)}}function Me(e){var t=e.name;if(je.has(t))return re.debug(`There were multiple attempts to register component ${t}.`),!1;je.set(t,e);var r,n=u(Ne.values());try{for(n.s();!(r=n.n()).done;){Re(r.value,e)}}catch(o){n.e(o)}finally{n.f()}var a,i=u(Pe.values());try{for(i.s();!(a=i.n()).done;){Re(a.value,e)}}catch(o){i.e(o)}finally{i.f()}return!0}function Be(e,t){var r=e.container.getProvider("heartbeat").getImmediate({optional:!0});return r&&r.triggerHeartbeat(),e.container.getProvider(t)}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */var Le=new S("app","Firebase",{"no-app":"No Firebase App '{$appName}' has been created - call initializeApp() first","bad-app-name":"Illegal App name: '{$appName}'","duplicate-app":"Firebase App named '{$appName}' already exists with different {$mismatchedParam}. Existing: '{$oldValue}'. New: '{$newValue}'.","app-deleted":"Firebase App named '{$appName}' already deleted","server-app-deleted":"Firebase Server App has been deleted","no-options":"Need to provide options, when not being deployed to hosting via source.","invalid-app-argument":"firebase.{$appName}() takes either no argument or a Firebase App instance.","invalid-log-argument":"First argument to `onLog` must be null or a function.","idb-open":"Error thrown when opening IndexedDB. Original error: {$originalErrorMessage}.","idb-get":"Error thrown when reading from IndexedDB. Original error: {$originalErrorMessage}.","idb-set":"Error thrown when writing to IndexedDB. Original error: {$originalErrorMessage}.","idb-delete":"Error thrown when deleting from IndexedDB. Original error: {$originalErrorMessage}.","finalization-registry-not-supported":"FirebaseServerApp deleteOnDeref field defined but the JS runtime does not support FinalizationRegistry.","invalid-server-app-environment":"FirebaseServerApp is not for use in browser environments."});
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
class $e{constructor(e,t,n){this._isDeleted=!1,this._options=r({},e),this._config=r({},t),this._name=t.name,this._automaticDataCollectionEnabled=t.automaticDataCollectionEnabled,this._container=n,this.container.addComponent(new C("app",()=>this,"PUBLIC"))}get automaticDataCollectionEnabled(){return this.checkDestroyed(),this._automaticDataCollectionEnabled}set automaticDataCollectionEnabled(e){this.checkDestroyed(),this._automaticDataCollectionEnabled=e}get name(){return this.checkDestroyed(),this._name}get options(){return this.checkDestroyed(),this._options}get config(){return this.checkDestroyed(),this._config}get container(){return this._container}get isDeleted(){return this._isDeleted}set isDeleted(e){this._isDeleted=e}checkDestroyed(){if(this.isDeleted)throw Le.create("app-deleted",{appName:this._name})}}function xe(e=Oe){var t=Ne.get(e);if(!t&&e===Oe&&g())return function(e,t={}){var n=e;"object"!=typeof t&&(t={name:t});var a=r({name:Oe,automaticDataCollectionEnabled:!0},t),i=a.name;if("string"!=typeof i||!i)throw Le.create("bad-app-name",{appName:String(i)});if(n||(n=g()),!n)throw Le.create("no-options");var o=Ne.get(i);if(o){if(I(n,o.options)){if(I(a,o.config))return o;throw Le.create("duplicate-app",{appName:i,mismatchedParam:"config",oldValue:JSON.stringify(o.config),newValue:JSON.stringify(a)})}throw Le.create("duplicate-app",{appName:i,mismatchedParam:"options",oldValue:JSON.stringify(o.options),newValue:JSON.stringify(n)})}var s,c=new A(i),f=u(je.values());try{for(f.s();!(s=f.n()).done;){var l=s.value;c.addComponent(l)}}catch(d){f.e(d)}finally{f.f()}var p=new $e(n,a,c);return Ne.set(i,p),p}();if(!t)throw Le.create("no-app",{appName:e});return t}function He(e,t,r){var n,a=null!==(n=Ae[e])&&void 0!==n?n:e;r&&(a+=`-${r}`);var i=a.match(/\s|\//),o=t.match(/\s|\//);if(i||o){var s=[`Unable to register library "${a}" with version "${t}":`];return i&&s.push(`library name "${a}" contains illegal characters (whitespace or "/")`),i&&o&&s.push("and"),o&&s.push(`version name "${t}" contains illegal characters (whitespace or "/")`),void re.warn(s.join(" "))}Me(new C(`${a}-version`,()=>({library:a,version:t}),"VERSION"))}
/**
             * @license
             * Copyright 2021 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */var Fe="firebase-heartbeat-store",Ke=null;function Ue(){return Ke||(Ke=q("firebase-heartbeat-database",1,{upgrade:(e,t)=>{if(0===t)try{e.createObjectStore(Fe)}catch(r){console.warn(r)}}}).catch(e=>{throw Le.create("idb-open",{originalErrorMessage:e.message})})),Ke}function Ve(e){return We.apply(this,arguments)}function We(){return(We=s(a().m(function e(t){var r,n,i,o,s;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.p=0,e.n=1,Ue();case 1:return r=e.v,n=r.transaction(Fe),e.n=2,n.objectStore(Fe).get(Ge(t));case 2:return i=e.v,e.n=3,n.done;case 3:return e.a(2,i);case 4:e.p=4,(s=e.v)instanceof k?re.warn(s.message):(o=Le.create("idb-get",{originalErrorMessage:null==s?void 0:s.message}),re.warn(o.message));case 5:return e.a(2)}},e,null,[[0,4]])}))).apply(this,arguments)}function ze(e,t){return qe.apply(this,arguments)}function qe(){return(qe=s(a().m(function e(t,r){var n,i,o,s,c;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.p=0,e.n=1,Ue();case 1:return n=e.v,i=n.transaction(Fe,"readwrite"),o=i.objectStore(Fe),e.n=2,o.put(r,Ge(t));case 2:return e.n=3,i.done;case 3:e.n=5;break;case 4:e.p=4,(c=e.v)instanceof k?re.warn(c.message):(s=Le.create("idb-set",{originalErrorMessage:null==c?void 0:c.message}),re.warn(s.message));case 5:return e.a(2)}},e,null,[[0,4]])}))).apply(this,arguments)}function Ge(e){return`${e.name}!${e.options.appId}`}
/**
             * @license
             * Copyright 2021 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */var Je;class Qe{constructor(e){this.container=e,this._heartbeatsCache=null;var t=this.container.getProvider("app").getImmediate();this._storage=new Xe(t),this._heartbeatsCachePromise=this._storage.read().then(e=>(this._heartbeatsCache=e,e))}triggerHeartbeat(){var e=this;return s(a().m(function t(){var r,n,i,o,s,c,u;return a().w(function(t){for(;;)switch(t.p=t.n){case 0:if(t.p=0,n=e.container.getProvider("platform-logger").getImmediate(),i=n.getPlatformInfoString(),o=Ye(),null!=(null===(r=e._heartbeatsCache)||void 0===r?void 0:r.heartbeats)){t.n=2;break}return t.n=1,e._heartbeatsCachePromise;case 1:if(e._heartbeatsCache=t.v,null!=(null===(s=e._heartbeatsCache)||void 0===s?void 0:s.heartbeats)){t.n=2;break}return t.a(2);case 2:if(e._heartbeatsCache.lastSentHeartbeatDate!==o&&!e._heartbeatsCache.heartbeats.some(e=>e.date===o)){t.n=3;break}return t.a(2);case 3:e._heartbeatsCache.heartbeats.push({date:o,agent:i}),e._heartbeatsCache.heartbeats.length>30&&(c=tt(e._heartbeatsCache.heartbeats),e._heartbeatsCache.heartbeats.splice(c,1));case 4:return t.a(2,e._storage.overwrite(e._heartbeatsCache));case 5:t.p=5,u=t.v,re.warn(u);case 6:return t.a(2)}},t,null,[[0,5]])}))()}getHeartbeatsHeader(){var e=this;return s(a().m(function t(){var r,n,i,o,s,c,u;return a().w(function(t){for(;;)switch(t.p=t.n){case 0:if(t.p=0,null!==e._heartbeatsCache){t.n=1;break}return t.n=1,e._heartbeatsCachePromise;case 1:if(null!=(null===(r=e._heartbeatsCache)||void 0===r?void 0:r.heartbeats)&&0!==e._heartbeatsCache.heartbeats.length){t.n=2;break}return t.a(2,"");case 2:if(n=Ye(),i=Ze(e._heartbeatsCache.heartbeats),o=i.heartbeatsToSend,s=i.unsentEntries,c=p(JSON.stringify({version:2,heartbeats:o})),e._heartbeatsCache.lastSentHeartbeatDate=n,!(s.length>0)){t.n=4;break}return e._heartbeatsCache.heartbeats=s,t.n=3,e._storage.overwrite(e._heartbeatsCache);case 3:t.n=5;break;case 4:e._heartbeatsCache.heartbeats=[],e._storage.overwrite(e._heartbeatsCache);case 5:return t.a(2,c);case 6:return t.p=6,u=t.v,re.warn(u),t.a(2,"")}},t,null,[[0,6]])}))()}}function Ye(){return(new Date).toISOString().substring(0,10)}function Ze(e,t=1024){var r,n=[],a=e.slice(),i=u(e);try{var o=function(){var e=r.value,i=n.find(t=>t.agent===e.agent);if(i){if(i.dates.push(e.date),et(n)>t)return i.dates.pop(),0}else if(n.push({agent:e.agent,dates:[e.date]}),et(n)>t)return n.pop(),0;a=a.slice(1)};for(i.s();!(r=i.n()).done&&0!==o(););}catch(s){i.e(s)}finally{i.f()}return{heartbeatsToSend:n,unsentEntries:a}}class Xe{constructor(e){this.app=e,this._canUseIndexedDBPromise=this.runIndexedDBEnvironmentCheck()}runIndexedDBEnvironmentCheck(){return s(a().m(function e(){return a().w(function(e){for(;;)switch(e.n){case 0:if(m()){e.n=1;break}return e.a(2,!1);case 1:return e.a(2,w().then(()=>!0).catch(()=>!1));case 2:return e.a(2)}},e)}))()}read(){var e=this;return s(a().m(function t(){var r;return a().w(function(t){for(;;)switch(t.n){case 0:return t.n=1,e._canUseIndexedDBPromise;case 1:if(t.v){t.n=2;break}return t.a(2,{heartbeats:[]});case 2:return t.n=3,Ve(e.app);case 3:if(null==(r=t.v)||!r.heartbeats){t.n=4;break}return t.a(2,r);case 4:return t.a(2,{heartbeats:[]});case 5:return t.a(2)}},t)}))()}overwrite(e){var t=this;return s(a().m(function r(){var n,i;return a().w(function(r){for(;;)switch(r.n){case 0:return r.n=1,t._canUseIndexedDBPromise;case 1:if(r.v){r.n=2;break}return r.a(2);case 2:return r.n=3,t.read();case 3:return i=r.v,r.a(2,ze(t.app,{lastSentHeartbeatDate:null!==(n=e.lastSentHeartbeatDate)&&void 0!==n?n:i.lastSentHeartbeatDate,heartbeats:e.heartbeats}));case 4:return r.a(2)}},r)}))()}add(e){var t=this;return s(a().m(function r(){var n,i;return a().w(function(r){for(;;)switch(r.n){case 0:return r.n=1,t._canUseIndexedDBPromise;case 1:if(r.v){r.n=2;break}return r.a(2);case 2:return r.n=3,t.read();case 3:return i=r.v,r.a(2,ze(t.app,{lastSentHeartbeatDate:null!==(n=e.lastSentHeartbeatDate)&&void 0!==n?n:i.lastSentHeartbeatDate,heartbeats:[...i.heartbeats,...e.heartbeats]}));case 4:return r.a(2)}},r)}))()}}function et(e){return p(JSON.stringify({version:2,heartbeats:e})).length}function tt(e){if(0===e.length)return-1;for(var t=0,r=e[0].date,n=1;n<e.length;n++)e[n].date<r&&(r=e[n].date,t=n);return t}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
Je="",Me(new C("platform-logger",e=>new X(e),"PRIVATE")),Me(new C("heartbeat",e=>new Qe(e),"PRIVATE")),He(ee,te,Je),He(ee,te,"esm2020"),He("fire-js","");var rt="@firebase/installations",nt="0.6.24",at=1e4,it=`w:${nt}`,ot="FIS_v2",st=36e5,ct=new S("installations","Installations",{"missing-app-config-values":'Missing App configuration value: "{$valueName}"',"not-registered":"Firebase Installation is not registered.","installation-not-found":"Firebase Installation not found.","request-failed":'{$requestName} request failed with error "{$serverCode} {$serverStatus}: {$serverMessage}"',"app-offline":"Could not process request. Application offline.","delete-pending-registration":"Can't delete installation while there is a pending registration request."});function ut(e){return e instanceof k&&e.code.includes("request-failed")}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function ft({projectId:e}){return`https://firebaseinstallations.googleapis.com/v1/projects/${e}/installations`}function lt(e){return{token:e.token,requestStatus:2,expiresIn:(t=e.expiresIn,Number(t.replace("s","000"))),creationTime:Date.now()};var t}function pt(e,t){return dt.apply(this,arguments)}function dt(){return(dt=s(a().m(function e(t,r){var n,i;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,r.json();case 1:return n=e.v,i=n.error,e.a(2,ct.create("request-failed",{requestName:t,serverCode:i.code,serverMessage:i.message,serverStatus:i.status}))}},e)}))).apply(this,arguments)}function ht({apiKey:e}){return new Headers({"Content-Type":"application/json",Accept:"application/json","x-goog-api-key":e})}function vt(e,{refreshToken:t}){var r=ht(e);return r.append("Authorization",function(e){return`${ot} ${e}`}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */(t)),r}function gt(e){return bt.apply(this,arguments)}function bt(){return(bt=s(a().m(function e(t){var r;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,t();case 1:if(!((r=e.v).status>=500&&r.status<600)){e.n=2;break}return e.a(2,t());case 2:return e.a(2,r)}},e)}))).apply(this,arguments)}function mt(e,t){return wt.apply(this,arguments)}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function wt(){return(wt=s(a().m(function e({appConfig:t,heartbeatServiceProvider:r},{fid:n}){var i,o,s,c,u,f,l,p,d;return a().w(function(e){for(;;)switch(e.n){case 0:if(i=ft(t),o=ht(t),!(s=r.getImmediate({optional:!0}))){e.n=2;break}return e.n=1,s.getHeartbeatsHeader();case 1:(c=e.v)&&o.append("x-firebase-client",c);case 2:return u={fid:n,authVersion:ot,appId:t.appId,sdkVersion:it},f={method:"POST",headers:o,body:JSON.stringify(u)},e.n=3,gt(()=>fetch(i,f));case 3:if(!(l=e.v).ok){e.n=5;break}return e.n=4,l.json();case 4:return p=e.v,d={fid:p.fid||n,registrationStatus:2,refreshToken:p.refreshToken,authToken:lt(p.authToken)},e.a(2,d);case 5:return e.n=6,pt("Create Installation",l);case 6:throw e.v;case 7:return e.a(2)}},e)}))).apply(this,arguments)}function yt(e){return new Promise(t=>{setTimeout(t,e)})}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
var kt=/^[cdef][\w-]{21}$/;function St(){try{var e=new Uint8Array(17);(self.crypto||self.msCrypto).getRandomValues(e),e[0]=112+e[0]%16;var t=function(e){var t=(r=e,btoa(String.fromCharCode(...r)).replace(/\+/g,"-").replace(/\//g,"_"));var r;return t.substr(0,22)}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */(e);return kt.test(t)?t:""}catch(r){return""}}function It(e){return`${e.appName}!${e.appId}`}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */var Et=new Map;function _t(e,t){var r=It(e);Ct(r,t),function(e,t){var r=Tt();r&&r.postMessage({key:e,fid:t});Ot()}(r,t)}function Ct(e,t){var r=Et.get(e);if(r){var n,a=u(r);try{for(a.s();!(n=a.n()).done;){(0,n.value)(t)}}catch(i){a.e(i)}finally{a.f()}}}var Dt=null;function Tt(){return!Dt&&"BroadcastChannel"in self&&((Dt=new BroadcastChannel("[Firebase] FID Change")).onmessage=e=>{Ct(e.data.key,e.data.fid)}),Dt}function Ot(){0===Et.size&&Dt&&(Dt.close(),Dt=null)}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */var At="firebase-installations-store",Nt=null;function Pt(){return Nt||(Nt=q("firebase-installations-database",1,{upgrade:(e,t)=>{if(0===t)e.createObjectStore(At)}})),Nt}function jt(e,t){return Rt.apply(this,arguments)}function Rt(){return(Rt=s(a().m(function e(t,r){var n,i,o,s,c;return a().w(function(e){for(;;)switch(e.n){case 0:return n=It(t),e.n=1,Pt();case 1:return i=e.v,o=i.transaction(At,"readwrite"),s=o.objectStore(At),e.n=2,s.get(n);case 2:return c=e.v,e.n=3,s.put(r,n);case 3:return e.n=4,o.done;case 4:return c&&c.fid===r.fid||_t(t,r.fid),e.a(2,r)}},e)}))).apply(this,arguments)}function Mt(e){return Bt.apply(this,arguments)}function Bt(){return(Bt=s(a().m(function e(t){var r,n,i;return a().w(function(e){for(;;)switch(e.n){case 0:return r=It(t),e.n=1,Pt();case 1:return n=e.v,i=n.transaction(At,"readwrite"),e.n=2,i.objectStore(At).delete(r);case 2:return e.n=3,i.done;case 3:return e.a(2)}},e)}))).apply(this,arguments)}function Lt(e,t){return $t.apply(this,arguments)}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function $t(){return($t=s(a().m(function e(t,r){var n,i,o,s,c,u;return a().w(function(e){for(;;)switch(e.n){case 0:return n=It(t),e.n=1,Pt();case 1:return i=e.v,o=i.transaction(At,"readwrite"),s=o.objectStore(At),e.n=2,s.get(n);case 2:if(c=e.v,void 0!==(u=r(c))){e.n=4;break}return e.n=3,s.delete(n);case 3:e.n=5;break;case 4:return e.n=5,s.put(u,n);case 5:return e.n=6,o.done;case 6:return!u||c&&c.fid===u.fid||_t(t,u.fid),e.a(2,u)}},e)}))).apply(this,arguments)}function xt(e){return Ht.apply(this,arguments)}function Ht(){return(Ht=s(a().m(function e(t){var r,n,i;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,Lt(t.appConfig,e=>{var n=Ft(e),a=Kt(t,n);return r=a.registrationPromise,a.installationEntry});case 1:if(""!==(n=e.v).fid){e.n=3;break}return e.n=2,r;case 2:return i=e.v,e.a(2,{installationEntry:i});case 3:return e.a(2,{installationEntry:n,registrationPromise:r})}},e)}))).apply(this,arguments)}function Ft(e){return qt(e||{fid:St(),registrationStatus:0})}function Kt(e,t){if(0===t.registrationStatus){if(!navigator.onLine)return{installationEntry:t,registrationPromise:Promise.reject(ct.create("app-offline"))};var r={fid:t.fid,registrationStatus:1,registrationTime:Date.now()},n=function(e,t){return Ut.apply(this,arguments)}(e,r);return{installationEntry:r,registrationPromise:n}}return 1===t.registrationStatus?{installationEntry:t,registrationPromise:Vt(e)}:{installationEntry:t}}function Ut(){return(Ut=s(a().m(function e(t,r){var n,i;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.p=0,e.n=1,mt(t,r);case 1:return n=e.v,e.a(2,jt(t.appConfig,n));case 2:if(e.p=2,!ut(i=e.v)||409!==i.customData.serverCode){e.n=4;break}return e.n=3,Mt(t.appConfig);case 3:e.n=5;break;case 4:return e.n=5,jt(t.appConfig,{fid:r.fid,registrationStatus:0});case 5:throw i;case 6:return e.a(2)}},e,null,[[0,2]])}))).apply(this,arguments)}function Vt(e){return Wt.apply(this,arguments)}function Wt(){return(Wt=s(a().m(function e(t){var r,n,i,o;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,zt(t.appConfig);case 1:r=e.v;case 2:if(1!==r.registrationStatus){e.n=5;break}return e.n=3,yt(100);case 3:return e.n=4,zt(t.appConfig);case 4:r=e.v,e.n=2;break;case 5:if(0!==r.registrationStatus){e.n=8;break}return e.n=6,xt(t);case 6:if(n=e.v,i=n.installationEntry,!(o=n.registrationPromise)){e.n=7;break}return e.a(2,o);case 7:return e.a(2,i);case 8:return e.a(2,r)}},e)}))).apply(this,arguments)}function zt(e){return Lt(e,e=>{if(!e)throw ct.create("installation-not-found");return qt(e)})}function qt(e){return 1===(t=e).registrationStatus&&t.registrationTime+at<Date.now()?{fid:e.fid,registrationStatus:0}:e;var t;
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */}function Gt(e,t){return Jt.apply(this,arguments)}function Jt(){return(Jt=s(a().m(function e({appConfig:t,heartbeatServiceProvider:r},n){var i,o,s,c,u,f,l,p,d;return a().w(function(e){for(;;)switch(e.n){case 0:if(i=Qt(t,n),o=vt(t,n),!(s=r.getImmediate({optional:!0}))){e.n=2;break}return e.n=1,s.getHeartbeatsHeader();case 1:(c=e.v)&&o.append("x-firebase-client",c);case 2:return u={installation:{sdkVersion:it,appId:t.appId}},f={method:"POST",headers:o,body:JSON.stringify(u)},e.n=3,gt(()=>fetch(i,f));case 3:if(!(l=e.v).ok){e.n=5;break}return e.n=4,l.json();case 4:return p=e.v,d=lt(p),e.a(2,d);case 5:return e.n=6,pt("Generate Auth Token",l);case 6:throw e.v;case 7:return e.a(2)}},e)}))).apply(this,arguments)}function Qt(e,{fid:t}){return`${ft(e)}/${t}/authTokens:generate`}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function Yt(e){return Zt.apply(this,arguments)}function Zt(){return(Zt=s(a().m(function e(t,r=!1){var n,i,o,s;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,Lt(t.appConfig,e=>{if(!ar(e))throw ct.create("not-registered");var a=e.authToken;if(!r&&ir(a))return e;if(1===a.requestStatus)return n=Xt(t,r),e;if(!navigator.onLine)throw ct.create("app-offline");var i=or(e);return n=rr(t,i),i});case 1:if(i=e.v,!n){e.n=3;break}return e.n=2,n;case 2:s=e.v,e.n=4;break;case 3:s=i.authToken;case 4:return o=s,e.a(2,o)}},e)}))).apply(this,arguments)}function Xt(e,t){return er.apply(this,arguments)}function er(){return(er=s(a().m(function e(t,r){var n,i;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,tr(t.appConfig);case 1:n=e.v;case 2:if(1!==n.authToken.requestStatus){e.n=5;break}return e.n=3,yt(100);case 3:return e.n=4,tr(t.appConfig);case 4:n=e.v,e.n=2;break;case 5:if(0!==(i=n.authToken).requestStatus){e.n=6;break}return e.a(2,Yt(t,r));case 6:return e.a(2,i);case 7:return e.a(2)}},e)}))).apply(this,arguments)}function tr(e){return Lt(e,e=>{if(!ar(e))throw ct.create("not-registered");var t,n=e.authToken;return 1===(t=n).requestStatus&&t.requestTime+at<Date.now()?r(r({},e),{},{authToken:{requestStatus:0}}):e})}function rr(e,t){return nr.apply(this,arguments)}function nr(){return(nr=s(a().m(function e(t,n){var i,o,s,c;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.p=0,e.n=1,Gt(t,n);case 1:return i=e.v,o=r(r({},n),{},{authToken:i}),e.n=2,jt(t.appConfig,o);case 2:return e.a(2,i);case 3:if(e.p=3,!ut(c=e.v)||401!==c.customData.serverCode&&404!==c.customData.serverCode){e.n=5;break}return e.n=4,Mt(t.appConfig);case 4:e.n=6;break;case 5:return s=r(r({},n),{},{authToken:{requestStatus:0}}),e.n=6,jt(t.appConfig,s);case 6:throw c;case 7:return e.a(2)}},e,null,[[0,3]])}))).apply(this,arguments)}function ar(e){return void 0!==e&&2===e.registrationStatus}function ir(e){return 2===e.requestStatus&&!function(e){var t=Date.now();return t<e.creationTime||e.creationTime+e.expiresIn<t+st}(e)}function or(e){var t={requestStatus:1,requestTime:Date.now()};return r(r({},e),{},{authToken:t})}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
function sr(){return(sr=s(a().m(function e(t){var r,n,i,o;return a().w(function(e){for(;;)switch(e.n){case 0:return r=t,e.n=1,xt(r);case 1:return n=e.v,i=n.installationEntry,(o=n.registrationPromise)?o.catch(console.error):Yt(r).catch(console.error),e.a(2,i.fid)}},e)}))).apply(this,arguments)}function cr(){return(cr=s(a().m(function e(t,r=!1){var n,i;return a().w(function(e){for(;;)switch(e.n){case 0:return n=t,e.n=1,ur(n);case 1:return e.n=2,Yt(n,r);case 2:return i=e.v,e.a(2,i.token)}},e)}))).apply(this,arguments)}function ur(e){return fr.apply(this,arguments)}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function fr(){return(fr=s(a().m(function e(t){var r,n;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,xt(t);case 1:if(r=e.v,!(n=r.registrationPromise)){e.n=2;break}return e.n=2,n;case 2:return e.a(2)}},e)}))).apply(this,arguments)}function lr(e,t){var r=e.appConfig;return function(e,t){Tt();var r=It(e),n=Et.get(r);n||(n=new Set,Et.set(r,n)),n.add(t)}(r,t),()=>{!function(e,t){var r=It(e),n=Et.get(r);n&&(n.delete(t),0===n.size&&Et.delete(r),Ot())}(r,t)}}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function pr(e){return ct.create("missing-app-config-values",{valueName:e})}
/**
             * @license
             * Copyright 2020 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */var dr="installations",hr=e=>{var t=Be(e.getProvider("app").getImmediate(),dr).getImmediate(),r={getId:()=>
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
function(e){return sr.apply(this,arguments)}(t),getToken:e=>function(e){return cr.apply(this,arguments)}(t,e)};return r};Me(new C(dr,e=>{var t=e.getProvider("app").getImmediate(),r=function(e){if(!e||!e.options)throw pr("App Configuration");if(!e.name)throw pr("App Name");for(var t=0,r=["projectId","apiKey","appId"];t<r.length;t++){var n=r[t];if(!e.options[n])throw pr(n)}return{appName:e.name,projectId:e.options.projectId,apiKey:e.options.apiKey,appId:e.options.appId}}(t);return{app:t,appConfig:r,heartbeatServiceProvider:Be(t,"heartbeat"),_delete:()=>Promise.resolve()}},"PUBLIC")),Me(new C("installations-internal",hr,"PRIVATE")),He(rt,nt),He(rt,nt,"esm2020");
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
var vr,gr,br="BDOU99-h67HcA6JeFXHbSNMu7e2yNNu3RzoMj8TM4W88jITfq7ZmPvIM1Iv-4_l2LxQcYwhqby2xGpWwzjfAnG4",mr="google.c.a.c_id";
/**
             * @license
             * Copyright 2017 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
function wr(e){var t=new Uint8Array(e);return btoa(String.fromCharCode(...t)).replace(/=/g,"").replace(/\+/g,"-").replace(/\//g,"_")}function yr(e){for(var t=(e+"=".repeat((4-e.length%4)%4)).replace(/\-/g,"+").replace(/_/g,"/"),r=atob(t),n=new Uint8Array(r.length),a=0;a<r.length;++a)n[a]=r.charCodeAt(a);return n}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */!function(e){e[e.DATA_MESSAGE=1]="DATA_MESSAGE",e[e.DISPLAY_NOTIFICATION=3]="DISPLAY_NOTIFICATION"}(vr||(vr={})),function(e){e.PUSH_RECEIVED="push-received",e.NOTIFICATION_CLICKED="notification-clicked",e.FID_REGISTERED="fid-registered"}(gr||(gr={}));var kr="fcm_token_details_db",Sr="fcm_token_object_Store";function Ir(e){return Er.apply(this,arguments)}function Er(){return Er=s(a().m(function e(t){var r,n,i;return a().w(function(e){for(;;)switch(e.n){case 0:if(!("databases"in indexedDB)){e.n=2;break}return e.n=1,indexedDB.databases();case 1:if(r=e.v,n=r.map(e=>e.name),n.includes(kr)){e.n=2;break}return e.a(2,null);case 2:return i=null,e.n=3,q(kr,5,{upgrade:function(){var e=s(a().m(function e(r,n,o,s){var c,u,f,l,p,d;return a().w(function(e){for(;;)switch(e.n){case 0:if(!(n<2)){e.n=1;break}return e.a(2);case 1:if(r.objectStoreNames.contains(Sr)){e.n=2;break}return e.a(2);case 2:return c=s.objectStore(Sr),e.n=3,c.index("fcmSenderId").get(t);case 3:return u=e.v,e.n=4,c.clear();case 4:if(u){e.n=5;break}return e.a(2);case 5:if(2!==n){e.n=7;break}if((l=u).auth&&l.p256dh&&l.endpoint){e.n=6;break}return e.a(2);case 6:i={token:l.fcmToken,createTime:null!==(f=l.createTime)&&void 0!==f?f:Date.now(),subscriptionOptions:{auth:l.auth,p256dh:l.p256dh,endpoint:l.endpoint,swScope:l.swScope,vapidKey:"string"==typeof l.vapidKey?l.vapidKey:wr(l.vapidKey)}},e.n=8;break;case 7:3===n?i={token:(p=u).fcmToken,createTime:p.createTime,subscriptionOptions:{auth:wr(p.auth),p256dh:wr(p.p256dh),endpoint:p.endpoint,swScope:p.swScope,vapidKey:wr(p.vapidKey)}}:4===n&&(i={token:(d=u).fcmToken,createTime:d.createTime,subscriptionOptions:{auth:wr(d.auth),p256dh:wr(d.p256dh),endpoint:d.endpoint,swScope:d.swScope,vapidKey:wr(d.vapidKey)}});case 8:return e.a(2)}},e)}));return function(t,r,n,a){return e.apply(this,arguments)}}()});case 3:return e.v.close(),e.n=4,G(kr);case 4:return e.n=5,G("fcm_vapid_details_db");case 5:return e.n=6,G("undefined");case 6:return e.a(2,_r(i)?i:null)}},e)})),Er.apply(this,arguments)}function _r(e){if(!e||!e.subscriptionOptions)return!1;var t=e.subscriptionOptions;return"number"==typeof e.createTime&&e.createTime>0&&"string"==typeof e.token&&e.token.length>0&&"string"==typeof t.auth&&t.auth.length>0&&"string"==typeof t.p256dh&&t.p256dh.length>0&&"string"==typeof t.endpoint&&t.endpoint.length>0&&"string"==typeof t.swScope&&t.swScope.length>0&&"string"==typeof t.vapidKey&&t.vapidKey.length>0}
/**
             * @license
             * Copyright 2017 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */var Cr=new S("messaging","Messaging",{"missing-app-config-values":'Missing App configuration value: "{$valueName}"',"only-available-in-window":"This method is available in a Window context.","only-available-in-sw":"This method is available in a service worker context.","permission-default":"The notification permission was not granted and dismissed instead.","permission-blocked":"The notification permission was not granted and blocked instead.","unsupported-browser":"This browser doesn't support the API's required to use the Firebase SDK.","indexed-db-unsupported":"This browser doesn't support indexedDb.open() (ex. Safari iFrame, Firefox Private Browsing, etc)","failed-service-worker-registration":"We are unable to register the default service worker. {$browserErrorMessage}","token-subscribe-failed":"A problem occurred while subscribing the user to FCM: {$errorInfo}","token-subscribe-no-token":"FCM returned no token when subscribing the user to push.","fid-registration-failed":"A problem occurred while creating an FCM registration via FID: {$errorInfo}","fid-unregister-failed":"A problem occurred while unregistering the FCM registration via FID: {$errorInfo}","fid-registration-idb-schema-unavailable":"Unable to read or persist FID registration metadata because the messaging IndexedDB schema is unavailable (for example, the database could not be upgraded to the latest version).","token-unsubscribe-failed":"A problem occurred while unsubscribing the user from FCM: {$errorInfo}","token-update-failed":"A problem occurred while updating the user from FCM: {$errorInfo}","token-update-no-token":"FCM returned no token when updating the user to push.","use-sw-after-get-token":"The useServiceWorker() method may only be called once and must be called before calling getToken() to ensure your service worker is used.","invalid-sw-registration":"The input to useServiceWorker() must be a ServiceWorkerRegistration.","invalid-bg-handler":"The input to setBackgroundMessageHandler() must be a function.","invalid-vapid-key":"The public VAPID key must be a string.","use-vapid-key-after-get-token":"The usePublicVapidKey() method may only be called once and must be called before calling getToken() to ensure your VAPID key is used.","invalid-on-registered-handler":"No onRegistered callback handler was provided or registered. Implement onRegistered() before register()."}),Dr="firebase-messaging-database",Tr="firebase-messaging-store",Or="firebase-messaging-fid-registration-store",Ar={openDB:q,deleteDB:G},Nr=null;function Pr(e){return{upgrade:(t,r)=>{!function(e,t,r){switch(t){case 0:if(e.createObjectStore(Tr),1===r)break;case 1:2===r&&e.createObjectStore(Or)}}(t,r,e)},blocked:()=>{},blocking:(e,t,r)=>{var n;Nr=null,null===(n=r.target)||void 0===n||n.close()},terminated:()=>{Nr=null}}}function jr(){if(!Nr){var e=Ar.openDB(Dr,2,Pr(2));Nr=e.catch(()=>Ar.openDB(Dr,1,Pr(1)))}return Nr}function Rr(e,t){return e.objectStoreNames.contains(t)}function Mr(e){if(!Rr(e,Or))throw Cr.create("fid-registration-idb-schema-unavailable")}function Br(e){return Lr.apply(this,arguments)}function Lr(){return(Lr=s(a().m(function e(t){var r,n,i,o;return a().w(function(e){for(;;)switch(e.n){case 0:return r=Gr(t),e.n=1,jr();case 1:return n=e.v,e.n=2,n.transaction(Tr).objectStore(Tr).get(r);case 2:if(!(i=e.v)){e.n=3;break}return e.a(2,i);case 3:return e.n=4,Ir(t.appConfig.senderId);case 4:if(!(o=e.v)){e.n=6;break}return e.n=5,$r(t,o);case 5:return e.a(2,o);case 6:return e.a(2)}},e)}))).apply(this,arguments)}function $r(e,t){return xr.apply(this,arguments)}function xr(){return(xr=s(a().m(function e(t,r){var n,i,o,s,c;return a().w(function(e){for(;;)switch(e.n){case 0:return n=Gr(t),e.n=1,jr();case 1:return i=e.v,o=[Tr],(s=Rr(i,Or))&&o.push(Or),c=i.transaction(o,"readwrite"),e.n=2,c.objectStore(Tr).put(r,n);case 2:if(!s){e.n=3;break}return e.n=3,c.objectStore(Or).delete(n);case 3:return e.n=4,c.done;case 4:return e.a(2,r)}},e)}))).apply(this,arguments)}function Hr(e){return Fr.apply(this,arguments)}function Fr(){return(Fr=s(a().m(function e(t){var r,n,i;return a().w(function(e){for(;;)switch(e.n){case 0:return r=Gr(t),e.n=1,jr();case 1:return n=e.v,i=n.transaction(Tr,"readwrite"),e.n=2,i.objectStore(Tr).delete(r);case 2:return e.n=3,i.done;case 3:return e.a(2)}},e)}))).apply(this,arguments)}function Kr(e){return Ur.apply(this,arguments)}function Ur(){return(Ur=s(a().m(function e(t){var r,n;return a().w(function(e){for(;;)switch(e.n){case 0:return r=Gr(t),e.n=1,jr();case 1:return Mr(n=e.v),e.n=2,n.transaction(Or).objectStore(Or).get(r);case 2:return e.a(2,e.v)}},e)}))).apply(this,arguments)}function Vr(e,t){return Wr.apply(this,arguments)}function Wr(){return(Wr=s(a().m(function e(t,r){var n,i,o;return a().w(function(e){for(;;)switch(e.n){case 0:return n=Gr(t),e.n=1,jr();case 1:return Mr(i=e.v),o=i.transaction([Tr,Or],"readwrite"),e.n=2,o.objectStore(Or).put(r,n);case 2:return e.n=3,o.objectStore(Tr).delete(n);case 3:return e.n=4,o.done;case 4:return e.a(2,r)}},e)}))).apply(this,arguments)}function zr(e){return qr.apply(this,arguments)}function qr(){return(qr=s(a().m(function e(t){var r,n,i;return a().w(function(e){for(;;)switch(e.n){case 0:return r=Gr(t),e.n=1,jr();case 1:return Mr(n=e.v),i=n.transaction(Or,"readwrite"),e.n=2,i.objectStore(Or).delete(r);case 2:return e.n=3,i.done;case 3:return e.a(2)}},e)}))).apply(this,arguments)}function Gr({appConfig:e}){return e.appId}var Jr="@firebase/messaging",Qr="0.13.3";function Yr(e,t){return Zr.apply(this,arguments)}function Zr(){return(Zr=s(a().m(function e(t,r){var n,i,o,s,c,u,f;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.n=1,vn(t);case 1:return n=e.v,i=mn(r,t.appConfig.appName,!1),o={method:"POST",headers:n,body:JSON.stringify(i)},e.p=2,e.n=3,fetch(hn(t.appConfig),o);case 3:return c=e.v,e.n=4,c.json();case 4:s=e.v,e.n=6;break;case 5:throw e.p=5,f=e.v,Cr.create("token-subscribe-failed",{errorInfo:null==f?void 0:f.toString()});case 6:if(!s.error){e.n=7;break}throw u=s.error.message,Cr.create("token-subscribe-failed",{errorInfo:u});case 7:if(s.token){e.n=8;break}throw Cr.create("token-subscribe-no-token");case 8:return e.a(2,s.token)}},e,null,[[2,5]])}))).apply(this,arguments)}function Xr(e,t){return en.apply(this,arguments)}function en(){return(en=s(a().m(function e(t,r){var n,i,o,s,c,u,f,l,p,d;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.n=1,vn(t);case 1:return o=e.v,s=mn(r,t.appConfig.appName,!0),c={method:"POST",headers:o,body:JSON.stringify(s)},e.p=2,e.n=3,pn(()=>fetch(hn(t.appConfig),c),3,1e3);case 3:u=e.v,e.n=5;break;case 4:throw e.p=4,d=e.v,Cr.create("fid-registration-failed",{errorInfo:null==d?void 0:d.toString()});case 5:if(!u.ok){e.n=7;break}return e.n=6,nn(u);case 6:return f=e.v,e.a(2,{responseFid:f});case 7:return e.p=7,e.n=8,u.json();case 8:l=e.v,e.n=10;break;case 9:throw e.p=9,e.v,Cr.create("fid-registration-failed",{errorInfo:u.statusText});case 10:throw p=null!==(n=null===(i=l.error)||void 0===i?void 0:i.message)&&void 0!==n?n:u.statusText,Cr.create("fid-registration-failed",{errorInfo:p});case 11:return e.a(2)}},e,null,[[7,9],[2,4]])}))).apply(this,arguments)}function tn(e,t){return rn.apply(this,arguments)}function rn(){return(rn=s(a().m(function e(t,r){var n,i,o,s,c,u,f,l;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.n=1,vn(t);case 1:return n=e.v,i={method:"DELETE",headers:n},e.p=2,e.n=3,fetch(`${hn(t.appConfig)}/${r}`,i);case 3:o=e.v,e.n=5;break;case 4:throw e.p=4,f=e.v,Cr.create("fid-unregister-failed",{errorInfo:null==f?void 0:f.toString()});case 5:if(!o.ok){e.n=6;break}return e.a(2);case 6:return e.p=6,e.n=7,o.json();case 7:throw u=e.v,null!==(s=null===(c=u.error)||void 0===c?void 0:c.message)&&void 0!==s?s:o.statusText;case 8:throw e.p=8,l=e.v,Cr.create("fid-unregister-failed",{errorInfo:"string"==typeof l&&l||o.statusText||(null==l?void 0:l.toString())});case 9:return e.a(2)}},e,null,[[6,8],[2,4]])}))).apply(this,arguments)}function nn(e){return an.apply(this,arguments)}function an(){return an=s(a().m(function e(t){var r,n,i;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.n=1,t.text();case 1:if((r=e.v).trim()){e.n=2;break}throw Cr.create("fid-registration-failed",{errorInfo:"CreateRegistration succeeded but response body is empty"});case 2:e.p=2,n=JSON.parse(r),e.n=4;break;case 3:throw e.p=3,e.v,Cr.create("fid-registration-failed",{errorInfo:"CreateRegistration succeeded but response body is not valid JSON"});case 4:if("string"==typeof(i=n.name)&&0!==i.length){e.n=5;break}throw Cr.create("fid-registration-failed",{errorInfo:"CreateRegistration succeeded but response did not include a non-empty name"});case 5:return e.a(2,sn(i))}},e,null,[[2,3]])})),an.apply(this,arguments)}var on="/registrations/";function sn(e){var t=e.indexOf(on);if(-1!==t){var r=e.slice(t+on.length);if(r.length>0)return r}throw Cr.create("fid-registration-failed",{errorInfo:"CreateRegistration succeeded but response name is not a valid registration resource name"})}function cn(e,t){return un.apply(this,arguments)}function un(){return(un=s(a().m(function e(t,r){var n,i,o,s,c,u,f;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.n=1,vn(t);case 1:return n=e.v,i=mn(r.subscriptionOptions,t.appConfig.appName,!1),o={method:"PATCH",headers:n,body:JSON.stringify(i)},e.p=2,e.n=3,fetch(`${hn(t.appConfig)}/${r.token}`,o);case 3:return c=e.v,e.n=4,c.json();case 4:s=e.v,e.n=6;break;case 5:throw e.p=5,f=e.v,Cr.create("token-update-failed",{errorInfo:null==f?void 0:f.toString()});case 6:if(!s.error){e.n=7;break}throw u=s.error.message,Cr.create("token-update-failed",{errorInfo:u});case 7:if(s.token){e.n=8;break}throw Cr.create("token-update-no-token");case 8:return e.a(2,s.token)}},e,null,[[2,5]])}))).apply(this,arguments)}function fn(e,t){return ln.apply(this,arguments)}function ln(){return(ln=s(a().m(function e(t,r){var n,i,o,s,c,u;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.n=1,vn(t);case 1:return n=e.v,i={method:"DELETE",headers:n},e.p=2,e.n=3,fetch(`${hn(t.appConfig)}/${r}`,i);case 3:return o=e.v,e.n=4,o.json();case 4:if(!(s=e.v).error){e.n=5;break}throw c=s.error.message,Cr.create("token-unsubscribe-failed",{errorInfo:c});case 5:e.n=7;break;case 6:throw e.p=6,u=e.v,Cr.create("token-unsubscribe-failed",{errorInfo:null==u?void 0:u.toString()});case 7:return e.a(2)}},e,null,[[2,6]])}))).apply(this,arguments)}function pn(e,t,r){return dn.apply(this,arguments)}function dn(){return(dn=s(a().m(function t(r,n,i){var o,s,c,u;return a().w(function(t){for(;;)switch(t.n){case 0:s=a().m(function e(){var t,s,c;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.p=0,e.n=1,r();case 1:return s=e.v,e.a(2,{v:s});case 2:if(e.p=2,c=e.v,o=c,!(u<n-1)){e.n=3;break}return t=i*Math.pow(2,u),e.n=3,new Promise(e=>setTimeout(e,t));case 3:return e.a(2)}},e,null,[[0,2]])}),u=0;case 1:if(!(u<n)){t.n=4;break}return t.d(e(s()),2);case 2:if(!(c=t.v)){t.n=3;break}return t.a(2,c.v);case 3:u++,t.n=1;break;case 4:throw o;case 5:return t.a(2)}},t)}))).apply(this,arguments)}function hn({projectId:e}){return`https://fcmregistrations.googleapis.com/v1/projects/${e}/registrations`}function vn(e){return gn.apply(this,arguments)}function gn(){return(gn=s(a().m(function e({appConfig:t,installations:r}){var n;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,r.getToken();case 1:return n=e.v,e.a(2,new Headers({"Content-Type":"application/json",Accept:"application/json","x-goog-api-key":t.apiKey,"x-goog-firebase-installations-auth":`FIS ${n}`}))}},e)}))).apply(this,arguments)}function bn(e,t){var r;try{if(/^[a-zA-Z][a-zA-Z\d+\-.]*:/.test(e))return new URL(e).host}catch(a){}try{var n;if("undefined"!=typeof self&&null!==(n=self.location)&&void 0!==n&&n.href)return new URL(e,self.location.origin).host}catch(i){}return"undefined"!=typeof self&&null!==(r=self.location)&&void 0!==r&&r.host?self.location.host:t}function mn({p256dh:e,auth:t,endpoint:r,vapidKey:n,swScope:a},i,o){var s={web:{origin:bn(a,i),endpoint:r,auth:t,p256dh:e}};return o&&(s.fcm_sdk_version=Qr),n!==br&&(s.web.applicationPubKey=n),s}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function wn(e){return yn.apply(this,arguments)}function yn(){return(yn=s(a().m(function e(t){var r,n,i,o;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.n=1,Nn(t.swRegistration,t.vapidKey);case 1:return r=e.v,n={vapidKey:t.vapidKey,swScope:t.swRegistration.scope,endpoint:r.endpoint,auth:wr(r.getKey("auth")),p256dh:wr(r.getKey("p256dh"))},e.n=2,Br(t.firebaseDependencies);case 2:if(i=e.v){e.n=3;break}return e.a(2,On(t.firebaseDependencies,n));case 3:if(jn(i.subscriptionOptions,n)){e.n=8;break}return e.p=4,e.n=5,fn(t.firebaseDependencies,i.token);case 5:e.n=7;break;case 6:e.p=6,o=e.v,console.warn(o);case 7:return e.a(2,On(t.firebaseDependencies,n));case 8:if(!(Date.now()>=i.createTime+6048e5)){e.n=9;break}return e.a(2,Dn(t,{token:i.token,createTime:Date.now(),subscriptionOptions:n}));case 9:return e.a(2,i.token);case 10:return e.a(2)}},e,null,[[4,6]])}))).apply(this,arguments)}function kn(e,t){return Sn.apply(this,arguments)}function Sn(){return(Sn=s(a().m(function e(t,r){return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,fn(t.firebaseDependencies,r.token);case 1:return e.n=2,Hr(t.firebaseDependencies);case 2:return e.n=3,Rn(t.firebaseDependencies);case 3:return e.a(2)}},e)}))).apply(this,arguments)}function In(e){return En.apply(this,arguments)}function En(){return(En=s(a().m(function e(t){var r,n;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,Kr(t.firebaseDependencies).catch(()=>{});case 1:if(r=e.v,!(n=null==r?void 0:r.fid)){e.n=2;break}return e.n=2,tn(t.firebaseDependencies,n);case 2:return e.n=3,Rn(t.firebaseDependencies);case 3:n&&Ln(t,n);case 4:return e.a(2)}},e)}))).apply(this,arguments)}function _n(e){return Cn.apply(this,arguments)}function Cn(){return(Cn=s(a().m(function e(t){var r,n;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,Br(t.firebaseDependencies);case 1:if(!(r=e.v)){e.n=3;break}return e.n=2,kn(t,r);case 2:e.n=4;break;case 3:return e.n=4,In(t);case 4:return e.n=5,t.swRegistration.pushManager.getSubscription();case 5:if(!(n=e.v)){e.n=6;break}return e.a(2,n.unsubscribe());case 6:return e.a(2,!0)}},e)}))).apply(this,arguments)}function Dn(e,t){return Tn.apply(this,arguments)}function Tn(){return(Tn=s(a().m(function e(t,n){var i,o;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.p=0,e.n=1,cn(t.firebaseDependencies,n);case 1:return i=e.v,o=r(r({},n),{},{token:i,createTime:Date.now()}),e.n=2,$r(t.firebaseDependencies,o);case 2:return e.a(2,i);case 3:throw e.p=3,e.v;case 4:return e.a(2)}},e,null,[[0,3]])}))).apply(this,arguments)}function On(e,t){return An.apply(this,arguments)}function An(){return(An=s(a().m(function e(t,r){var n,i;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,Yr(t,r);case 1:return n=e.v,i={token:n,createTime:Date.now(),subscriptionOptions:r},e.n=2,$r(t,i);case 2:return e.a(2,i.token)}},e)}))).apply(this,arguments)}function Nn(e,t){return Pn.apply(this,arguments)}function Pn(){return(Pn=s(a().m(function e(t,r){var n;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,t.pushManager.getSubscription();case 1:if(!(n=e.v)){e.n=2;break}return e.a(2,n);case 2:return e.a(2,t.pushManager.subscribe({userVisibleOnly:!0,applicationServerKey:yr(r)}))}},e)}))).apply(this,arguments)}function jn(e,t){var r=t.vapidKey===e.vapidKey,n=t.endpoint===e.endpoint,a=t.auth===e.auth,i=t.p256dh===e.p256dh;return r&&n&&a&&i}function Rn(e){return Mn.apply(this,arguments)}function Mn(){return(Mn=s(a().m(function e(t){return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.p=0,e.n=1,zr(t);case 1:e.n=3;break;case 2:e.p=2,e.v;case 3:return e.a(2)}},e,null,[[0,2]])}))).apply(this,arguments)}function Bn(e,t){var r=e.onRegisteredHandler;r&&("function"==typeof r?r(t):r.next(t))}function Ln(e,t){var r=e.onUnregisteredHandler;r&&("function"==typeof r?r(t):r.next(t))}
/**
             * @license
             * Copyright 2020 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function $n(e){return xn.apply(this,arguments)}function xn(){return(xn=s(a().m(function e(t){var r;return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.p=0,e.n=1,navigator.serviceWorker.register("/firebase-messaging-sw.js",{scope:"/firebase-cloud-messaging-push-scope"});case 1:return t.swRegistration=e.v,t.swRegistration.update().catch(()=>{}),e.n=2,Hn(t.swRegistration);case 2:e.n=4;break;case 3:throw e.p=3,r=e.v,Cr.create("failed-service-worker-registration",{browserErrorMessage:null==r?void 0:r.message});case 4:return e.a(2)}},e,null,[[0,3]])}))).apply(this,arguments)}function Hn(e){return Fn.apply(this,arguments)}
/**
             * @license
             * Copyright 2020 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function Fn(){return(Fn=s(a().m(function e(t){return a().w(function(e){for(;;)if(0===e.n)return e.a(2,new Promise((e,r)=>{var n=setTimeout(()=>r(new Error("Service worker not registered after 10000 ms")),1e4),a=t.installing||t.waiting;t.active?(clearTimeout(n),e()):a?a.onstatechange=t=>{var r;"activated"===(null===(r=t.target)||void 0===r?void 0:r.state)&&(a.onstatechange=null,clearTimeout(n),e())}:(clearTimeout(n),r(new Error("No incoming service worker found.")))}))},e)}))).apply(this,arguments)}function Kn(e,t){return Un.apply(this,arguments)}
/**
             * @license
             * Copyright 2020 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function Un(){return(Un=s(a().m(function e(t,r){return a().w(function(e){for(;;)switch(e.n){case 0:if(r||t.swRegistration){e.n=1;break}return e.n=1,$n(t);case 1:if(r||!t.swRegistration){e.n=2;break}return e.a(2);case 2:if(r instanceof ServiceWorkerRegistration){e.n=3;break}throw Cr.create("invalid-sw-registration");case 3:t.swRegistration=r;case 4:return e.a(2)}},e)}))).apply(this,arguments)}function Vn(e,t){return Wn.apply(this,arguments)}
/**
             * @license
             * Copyright 2020 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function Wn(){return(Wn=s(a().m(function e(t,r){return a().w(function(e){for(;;)switch(e.n){case 0:r?t.vapidKey=r:t.vapidKey||(t.vapidKey=br);case 1:return e.a(2)}},e)}))).apply(this,arguments)}function zn(e,t){return qn.apply(this,arguments)}function qn(){return(qn=s(a().m(function e(t,r){var n,i,o,s,c;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,Gn(t.swRegistration,t.vapidKey);case 1:n=e.v,i={vapidKey:t.vapidKey,swScope:t.swRegistration.scope,endpoint:n.endpoint,auth:wr(n.getKey("auth")),p256dh:wr(n.getKey("p256dh"))},o=t.firebaseDependencies.installations,s=0;case 2:if(!(s<3)){e.n=6;break}return e.n=3,Xr(t.firebaseDependencies,i);case 3:if(c=e.v,c.responseFid!==r){e.n=4;break}return e.a(2);case 4:if(!(s<2)){e.n=5;break}return e.n=5,o.getToken(!0);case 5:s++,e.n=2;break;case 6:throw Cr.create("fid-registration-failed",{errorInfo:"CreateRegistration response FID does not match Firebase Installation ID"});case 7:return e.a(2)}},e)}))).apply(this,arguments)}function Gn(e,t){return Jn.apply(this,arguments)}
/**
             * @license
             * Copyright 2020 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function Jn(){return(Jn=s(a().m(function e(t,r){var n;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,t.pushManager.getSubscription();case 1:if(!(n=e.v)){e.n=2;break}return e.a(2,n);case 2:return e.a(2,t.pushManager.subscribe({userVisibleOnly:!0,applicationServerKey:yr(r)}))}},e)}))).apply(this,arguments)}function Qn(e,t){return Yn.apply(this,arguments)}
/**
             * @license
             * Copyright 2026 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function Yn(){return(Yn=s(a().m(function e(t,r){var n;return a().w(function(e){for(;;)switch(e.n){case 0:if(navigator){e.n=1;break}throw Cr.create("only-available-in-window");case 1:if("default"!==Notification.permission){e.n=2;break}return e.n=2,Notification.requestPermission();case 2:if("granted"===Notification.permission){e.n=3;break}throw Cr.create("permission-blocked");case 3:if(t.onRegisteredHandler){e.n=4;break}throw Cr.create("invalid-on-registered-handler");case 4:return e.n=5,Vn(t,null==r?void 0:r.vapidKey);case 5:return e.n=6,Kn(t,null==r?void 0:r.serviceWorkerRegistration);case 6:return n=t._registerNotifyChain.catch(()=>{}),t._registerNotifyChain=n.then(s(a().m(function e(){var r,n,i;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,t.firebaseDependencies.installations.getId();case 1:return r=e.v,e.n=2,Kr(t.firebaseDependencies);case 2:if(n=e.v,i=Date.now(),!(!n||n.fid!==r||i>=n.lastRegisterTime+6048e5)){e.n=4;break}return e.n=3,zn(t,r);case 3:return e.n=4,Vr(t.firebaseDependencies,{fid:r,lastRegisterTime:i,vapidKey:t.vapidKey});case 4:if(t.onRegisteredHandler){e.n=5;break}throw Cr.create("invalid-on-registered-handler");case 5:Bn(t,r);case 6:return e.a(2)}},e)}))),e.a(2,t._registerNotifyChain)}},e)}))).apply(this,arguments)}
/**
             * @license
             * Copyright 2020 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
function Zn(e){var t={from:e.from,collapseKey:e.collapse_key,messageId:e.fcmMessageId};return function(e,t){if(!t.notification)return;e.notification={};var r=t.notification.title;r&&(e.notification.title=r);var n=t.notification.body;n&&(e.notification.body=n);var a=t.notification.image;a&&(e.notification.image=a);var i=t.notification.icon;i&&(e.notification.icon=i)}(t,e),function(e,t){if(!t.data)return;e.data=t.data}(t,e),function(e,t){var r,n,a,i,o;if(!(t.fcmOptions||null!==(r=t.notification)&&void 0!==r&&r.click_action))return;e.fcmOptions={};var s=null!==(n=null===(a=t.fcmOptions)||void 0===a?void 0:a.link)&&void 0!==n?n:null===(i=t.notification)||void 0===i?void 0:i.click_action;s&&(e.fcmOptions.link=s);var c=null===(o=t.fcmOptions)||void 0===o?void 0:o.analytics_label;c&&(e.fcmOptions.analyticsLabel=c)}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */(t,e),t}function Xn(e){return"object"==typeof e&&!!e&&mr in e}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function ea(e){return Cr.create("missing-app-config-values",{valueName:e})}
/**
             * @license
             * Copyright 2020 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */class ta{constructor(e,t,r){this.deliveryMetricsExportedToBigQueryEnabled=!1,this.onBackgroundMessageHandler=null,this.onMessageHandler=null,this.onRegisteredHandler=null,this.onUnregisteredHandler=null,this._registerNotifyChain=Promise.resolve(),this._fidChangeUnsubscribe=null,this.logEvents=[],this.logQueue={state:"stopped"};var n=function(e){if(!e||!e.options)throw ea("App Configuration Object");if(!e.name)throw ea("App Name");for(var t=e.options,r=0,n=["projectId","apiKey","appId","messagingSenderId"];r<n.length;r++){var a=n[r];if(!t[a])throw ea(a)}return{appName:e.name,projectId:t.projectId,apiKey:t.apiKey,appId:t.appId,senderId:t.messagingSenderId}}(e);this.firebaseDependencies={app:e,appConfig:n,installations:t,analyticsProvider:r}}_delete(){return this._fidChangeUnsubscribe&&(this._fidChangeUnsubscribe(),this._fidChangeUnsubscribe=null),"scheduled"===this.logQueue.state&&clearTimeout(this.logQueue.timerId),this.logQueue={state:"stopped"},Promise.resolve()}}
/**
             * @license
             * Copyright 2020 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function ra(e,t){return na.apply(this,arguments)}
/**
             * @license
             * Copyright 2019 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function na(){return(na=s(a().m(function e(t,r){return a().w(function(e){for(;;)switch(e.n){case 0:if(navigator){e.n=1;break}throw Cr.create("only-available-in-window");case 1:if("default"!==Notification.permission){e.n=2;break}return e.n=2,Notification.requestPermission();case 2:if("granted"===Notification.permission){e.n=3;break}throw Cr.create("permission-blocked");case 3:return e.n=4,Vn(t,null==r?void 0:r.vapidKey);case 4:return e.n=5,Kn(t,null==r?void 0:r.serviceWorkerRegistration);case 5:return e.a(2,wn(t))}},e)}))).apply(this,arguments)}function aa(e,t,r){return ia.apply(this,arguments)}function ia(){return(ia=s(a().m(function e(t,r,n){var i;return a().w(function(e){for(;;)switch(e.n){case 0:return i=oa(r),e.n=1,t.firebaseDependencies.analyticsProvider.get();case 1:e.v.logEvent(i,{message_id:n[mr],message_name:n["google.c.a.c_l"],message_time:n["google.c.a.ts"],message_device_time:Math.floor(Date.now()/1e3)});case 2:return e.a(2)}},e)}))).apply(this,arguments)}function oa(e){switch(e){case gr.NOTIFICATION_CLICKED:return"notification_open";case gr.PUSH_RECEIVED:return"notification_foreground";default:throw new Error}}
/**
             * @license
             * Copyright 2017 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
/**
             * @license
             * Copyright 2020 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
function sa(){return(sa=s(a().m(function e(t,r){var n,i,o;return a().w(function(e){for(;;)switch(e.n){case 0:if((n=r.data).isFirebaseMessaging){e.n=1;break}return e.a(2);case 1:if(t.onMessageHandler&&n.messageType===gr.PUSH_RECEIVED&&("function"==typeof t.onMessageHandler?t.onMessageHandler(Zn(n)):t.onMessageHandler.next(Zn(n))),t.onRegisteredHandler&&n.messageType===gr.FID_REGISTERED&&(i=n.fid,"function"==typeof t.onRegisteredHandler?t.onRegisteredHandler(i):t.onRegisteredHandler.next(i)),!Xn(o=n.data)||"1"!==o["google.c.a.e"]){e.n=2;break}return e.n=2,aa(t,n.messageType,o);case 2:return e.a(2)}},e)}))).apply(this,arguments)}var ca=e=>{var t=new ta(e.getProvider("app").getImmediate(),e.getProvider("installations-internal").getImmediate(),e.getProvider("analytics-internal"));return navigator.serviceWorker.addEventListener("message",e=>function(e,t){return sa.apply(this,arguments)}(t,e)),t._fidChangeUnsubscribe=function(e,t){return lr(t,()=>{s(a().m(function t(){return a().w(function(t){for(;;)switch(t.n){case 0:if(e.onRegisteredHandler){t.n=1;break}return t.a(2);case 1:return t.n=2,Kr(e.firebaseDependencies);case 2:if(t.v){t.n=3;break}return t.a(2);case 3:return t.n=4,Qn(e).catch(()=>{});case 4:return t.a(2)}},t)}))()})}(t,e.getProvider("installations").getImmediate()),t},ua=e=>{var t=e.getProvider("messaging").getImmediate();return{getToken:e=>ra(t,e),register:e=>Qn(t,e)}};
/**
             * @license
             * Copyright 2020 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
function fa(){return la.apply(this,arguments)}
/**
             * @license
             * Copyright 2020 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */function la(){return(la=s(a().m(function e(){return a().w(function(e){for(;;)switch(e.p=e.n){case 0:return e.p=0,e.n=1,w();case 1:e.n=3;break;case 2:return e.p=2,e.v,e.a(2,!1);case 3:return e.a(2,"undefined"!=typeof window&&m()&&y()&&"serviceWorker"in navigator&&"PushManager"in window&&"Notification"in window&&"fetch"in window&&ServiceWorkerRegistration.prototype.hasOwnProperty("showNotification")&&PushSubscription.prototype.hasOwnProperty("getKey"))}},e,null,[[0,2]])}))).apply(this,arguments)}
/**
             * @license
             * Copyright 2020 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
function pa(){return(pa=s(a().m(function e(t){return a().w(function(e){for(;;)switch(e.n){case 0:if(navigator){e.n=1;break}throw Cr.create("only-available-in-window");case 1:if(t.swRegistration){e.n=2;break}return e.n=2,$n(t);case 2:return e.a(2,_n(t))}},e)}))).apply(this,arguments)}
/**
             * @license
             * Copyright 2017 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */
function da(e=xe()){return fa().then(e=>{if(!e)throw Cr.create("unsupported-browser")},e=>{throw Cr.create("indexed-db-unsupported")}),Be(_(e),"messaging").getImmediate()}function ha(e,t){return va.apply(this,arguments)}function va(){return(va=s(a().m(function e(t,r){return a().w(function(e){for(;;)if(0===e.n)return t=_(t),e.a(2,ra(t,r))},e)}))).apply(this,arguments)}function ga(e){return function(e){return pa.apply(this,arguments)}(e=_(e))}function ba(e,t){return function(e,t){if(!navigator)throw Cr.create("only-available-in-window");return e.onMessageHandler=t,()=>{e.onMessageHandler=null}}(e=_(e),t)}
/**
             * @license
             * Copyright 2017 Google LLC
             *
             * Licensed under the Apache License, Version 2.0 (the "License");
             * you may not use this file except in compliance with the License.
             * You may obtain a copy of the License at
             *
             *   http://www.apache.org/licenses/LICENSE-2.0
             *
             * Unless required by applicable law or agreed to in writing, software
             * distributed under the License is distributed on an "AS IS" BASIS,
             * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
             * See the License for the specific language governing permissions and
             * limitations under the License.
             */Me(new C("messaging",ca,"PUBLIC")),Me(new C("messaging-internal",ua,"PRIVATE")),He(Jr,Qr),He(Jr,Qr,"esm2020");class ma extends i{constructor(){super(),fa().then(e=>{e&&ba(da(),e=>this.handleNotificationReceived(e))})}checkPermissions(){var e=this;return s(a().m(function t(){var r;return a().w(function(t){for(;;)switch(t.n){case 0:return t.n=1,fa();case 1:if(t.v){t.n=2;break}return t.a(2,{receive:"denied"});case 2:return r=e.convertNotificationPermissionToPermissionState(Notification.permission),t.a(2,{receive:r})}},t)}))()}requestPermissions(){var e=this;return s(a().m(function t(){var r,n;return a().w(function(t){for(;;)switch(t.n){case 0:return t.n=1,fa();case 1:if(t.v){t.n=2;break}return t.a(2,{receive:"denied"});case 2:return t.n=3,Notification.requestPermission();case 3:return r=t.v,n=e.convertNotificationPermissionToPermissionState(r),t.a(2,{receive:n})}},t)}))()}isSupported(){return s(a().m(function e(){var t;return a().w(function(e){for(;;)switch(e.n){case 0:return e.n=1,fa();case 1:return t=e.v,e.a(2,{isSupported:t})}},e)}))()}getToken(e){return s(a().m(function t(){var r,n;return a().w(function(t){for(;;)switch(t.n){case 0:return r=da(),t.n=1,ha(r,{vapidKey:e.vapidKey,serviceWorkerRegistration:e.serviceWorkerRegistration});case 1:return n=t.v,t.a(2,{token:n})}},t)}))()}deleteToken(){return s(a().m(function e(){var t;return a().w(function(e){for(;;)switch(e.n){case 0:return t=da(),e.n=1,ga(t);case 1:return e.a(2)}},e)}))()}getDeliveredNotifications(){var e=this;return s(a().m(function t(){return a().w(function(t){for(;;)switch(t.n){case 0:e.throwUnimplementedError();case 1:return t.a(2)}},t)}))()}removeDeliveredNotifications(e){var t=this;return s(a().m(function e(){return a().w(function(e){for(;;)switch(e.n){case 0:t.throwUnimplementedError();case 1:return e.a(2)}},e)}))()}removeAllDeliveredNotifications(){var e=this;return s(a().m(function t(){return a().w(function(t){for(;;)switch(t.n){case 0:e.throwUnimplementedError();case 1:return t.a(2)}},t)}))()}subscribeToTopic(e){var t=this;return s(a().m(function e(){return a().w(function(e){for(;;)switch(e.n){case 0:t.throwUnimplementedError();case 1:return e.a(2)}},e)}))()}unsubscribeFromTopic(e){var t=this;return s(a().m(function e(){return a().w(function(e){for(;;)switch(e.n){case 0:t.throwUnimplementedError();case 1:return e.a(2)}},e)}))()}createChannel(e){var t=this;return s(a().m(function e(){return a().w(function(e){for(;;)switch(e.n){case 0:t.throwUnimplementedError();case 1:return e.a(2)}},e)}))()}deleteChannel(e){var t=this;return s(a().m(function e(){return a().w(function(e){for(;;)switch(e.n){case 0:t.throwUnimplementedError();case 1:return e.a(2)}},e)}))()}listChannels(){var e=this;return s(a().m(function t(){return a().w(function(t){for(;;)switch(t.n){case 0:e.throwUnimplementedError();case 1:return t.a(2)}},t)}))()}handleNotificationReceived(e){var t={notification:this.createNotificationResult(e)};this.notifyListeners(ma.notificationReceivedEvent,t)}createNotificationResult(e){var t,r,n;return{body:null===(t=e.notification)||void 0===t?void 0:t.body,data:e.data,id:e.messageId,image:null===(r=e.notification)||void 0===r?void 0:r.image,title:null===(n=e.notification)||void 0===n?void 0:n.title}}convertNotificationPermissionToPermissionState(e){var t="prompt";switch(e){case"granted":t="granted";break;case"denied":t="denied"}return t}throwUnimplementedError(){throw this.unimplemented("Not implemented on web.")}}t("FirebaseMessagingWeb",ma),ma.notificationReceivedEvent="notificationReceived"}}})}();
