--- Define the Rotation Builder main Object.
RotationBuilder = {
	serializer = nil,

	-- The list of rotations generator.
	defaultRotationGenerator = {},
};

--- Import a rotation.
-- Unserialize a string as a Rotation and import it.
-- @param #string serializedRotation the serialized Rotation to import.
function RotationBuilder:importRotation(serializedRotation)
	if (not self.serializer) then
		-- Initialize the libraries when needed.
		self:initialize();
	end

	-- Deserialize
	local hasWork, addonName, rotationName, deSerialized = self.serializer:Deserialize(serializedRotation);

	-- Verify
	if(hasWork and (addonName == "RotationBuilder")) then
		if (not rotationName) then
			-- No rotation name found.
			print(L['ROB_UI_IMPORT_ERROR1']);
			return
		end
		if (ROB_Rotations[rotationName]) then
			-- A rotation with the same name already exist.
			print(L['ROB_UI_IMPORT_ERROR2']..":"..rotationName);
			return
		end
		
		local tempRotation = RotationBuilderUtils:restoreTable({}, deSerialized);
		ROB_Rotations[rotationName] = tempRotation;

		-- update rotation list
		ROB_SortRotationList();

		-- update the action list
		ROB_ActionList_Update();

		-- sort spell lists
		ROB_SortSpellLists();

		-- sort spells
		ROB_SortSpells();

		-- update the spells list
		ROB_SpellList_Update();

		-- update rotation modify buttons
		ROB_RotationModifyButtons_UpdateUI();

		-- update rotation ui stuff
		ROB_Rotation_Edit_UpdateUI();

		print(L['ROB_UI_IMPORT_SUCCESS']..":"..rotationName);
	else
		-- Not a rotation builder import.
		print(L['ROB_UI_IMPORT_ERROR3']);
	end
end

--- Export a rotation.
-- Serialize a Rotation as a string for export purpose.
-- @param #string rotationName the name of the rotation to export.
-- @return #string the exported rotation as a String.
function RotationBuilder:exportRotation(rotationName)
	-- Verify.
	-- TODO PEL : We need to localize these messages.
	if ((not rotationName) or (rotationName == "")) then
		print("No rotation name specified for export")
		return
	end

	local tempRotationData = ROB_Rotations[rotationName];
	if (not tempRotationData) then
		print("Rotation name must be the name of an rotation build, and is case-sensitive."..rotationName)
		return
	end

	if (not self.serializer) then
		-- Initialize the libraries when needed.
		self:initialize();
	end

	-- We must clean-up the data before serializing them.
	local toSerialize = RotationBuilderUtils:copyTable(tempRotationData, true);

	--@do-not-package@
	-- Register export information for development purpose.
	ROB_Exports[rotationName] = toSerialize;
	--@end-do-not-package@

	-- Serializing
	local rotation = self.serializer:Serialize("RotationBuilder", rotationName, toSerialize);
	return rotation;
end

--- Register a rotations generator for a class.
-- @param #string className the class for which we want to add a rotation generator.
-- @param #function method the method which will generate the rotation.
function RotationBuilder:addDefaultRotationsGenerator(className, method)
	if(not className or not method) then
		print("className or method is nil.");
		return
	end
	if (self.defaultRotationGenerator[className]) then
		-- TODO PEL : Localized this error message.
		print("Override rotations generator for "..className);
	end

	-- Register the generator.
	self.defaultRotationGenerator[className] = method;
end

--- Load default rotations for a class.
-- @param #string className the name of the class for which we must load default rotations.
function RotationBuilder:loadDefaultRotations(className)
	if (not self.defaultRotationGenerator[className]) then
		-- TODO PEL : Localized this error message.
		print("No default rotation available for "..className);
		return
	end

	-- Load default rotations for this class.
	local defaultRotation = self.defaultRotationGenerator[className]();
	for key, value in pairs(defaultRotation) do
		if(ROB_Rotations[key]) then
			-- If a rotation with the same name already exist.
			print(L['ROB_UI_DEBUG_PREFIX']..key..":"..L['ROB_UI_IMPORT_ERROR2']);
		else
			-- We can import the rotation.
			ROB_Rotations[key] = value;
		end
	end
end

--- Initialize the RotationBuilder Object.
function RotationBuilder:initialize()
	self.serializer = LibStub:GetLibrary("AceSerializer-3.0");
end