/*******************************************************************************
 * Copyright (c) 2016 Kiel University and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Kiel University - initial API and implementation
 *******************************************************************************/
package org.eclipse.elk.core.meta.validation

import java.util.Map
import org.eclipse.elk.core.meta.metaData.MdAlgorithm
import org.eclipse.elk.core.meta.metaData.MdBundle
import org.eclipse.elk.core.meta.metaData.MdBundleMember
import org.eclipse.elk.core.meta.metaData.MdGroup
import org.eclipse.elk.core.meta.metaData.MdProperty
import org.eclipse.elk.core.meta.metaData.MdPropertySupport
import org.eclipse.xtext.validation.Check

import static org.eclipse.elk.core.meta.metaData.MetaDataPackage.Literals.*
import org.eclipse.elk.core.meta.metaData.MdCategory

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class MetaDataValidator extends AbstractMetaDataValidator {
	
    @Check
    def void checkDuplicateMemberId(MdBundle bundle) {
        bundle.members.checkDuplicatePropertyIds
    }
    
    def void checkDuplicatePropertyIds(Iterable<? extends MdBundleMember> elements) {
        val Map<String, MdAlgorithm> algorithmIds = newHashMap
        val Map<String, MdCategory> categoryIds = newHashMap
        val Map<String, MdProperty> propertyIds = newHashMap
        val Map<String, MdGroup> groupIds = newHashMap
        for (element : elements) {
            switch element {
                MdAlgorithm: algorithmIds.checkExistsAndRemember(element)
                MdCategory: categoryIds.checkExistsAndRemember(element)
                MdGroup: {
                    groupIds.checkExistsAndRemember(element)
                    element.children.checkDuplicatePropertyIds
                }
                MdProperty: propertyIds.checkExistsAndRemember(element)
            }
        }
    }
    
    def  <T extends MdBundleMember> void checkExistsAndRemember(Map<String, T> map, T element) {
        if (map.containsKey(element.name)) {
                val otherMember = map.get(element.name)
                if (otherMember !== null) {
                    duplicateName(otherMember)
                    // The first occurrence should be marked only once
                    map.put(element.name, null)
                }
                duplicateName(element)
            } else {
                map.put(element.name, element)
            }
    }
    
    def void duplicateName(MdBundleMember member) {
        error("The id '" + member.name + "' is already used.", member, MD_BUNDLE_MEMBER__NAME)
    }
    
    @Check
    def void checkDuplicateOption(MdPropertySupport support) {
        if (support.property !== null && support.duplicated) {
            val algorithm = support.eContainer as MdAlgorithm
            if (algorithm.eContainer == support.property.eContainer)
                error("A property defined in the same bundle cannot be duplicated.", MD_PROPERTY_SUPPORT__DUPLICATED)
        }
    }
	
}
