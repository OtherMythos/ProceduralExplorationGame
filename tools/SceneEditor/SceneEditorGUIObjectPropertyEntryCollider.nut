
::SceneEditorFramework.SceneEditorGUIObjectPropertyEntryCollider <- class extends ::SceneEditorFramework.GUIObjectProperties.EntryDataPanel{

    mColliderTypes_ = null;
    mEntry_ = null;

    function setup(){
        local layout = _gui.createLayoutLine();

        local label = mWindow_.createLabel();
        label.setText("Collider");
        layout.addCell(label);

        mColliderTypes_ = mWindow_.createSpinner();
        mColliderTypes_.setOptions(["Circle", "Rectangle"]);
        mColliderTypes_.attachListenerForEvent(function(widget, action){
            local value = widget.getValueRaw();
            print(value);
            //::Base.setEditingTileRotation(value);

            local action = ::SceneEditorFramework.Actions[SceneEditorFramework_Action.USER_2]();
            assert(mEntry_ != null);
            assert(mEntry_.entryId != 0);
            action.populate(mEntry_.entryId, mEntry_.data.value, value);
            ::Base.mEditorBase.mActionStack_.pushAction_(action);
            action.performAction();
        }, _GUI_ACTION_VALUE_CHANGED, this);
        layout.addCell(mColliderTypes_);

        layout.layout();
    }

    function setEntry(entry){
        mEntry_ = entry;

        mColliderTypes_.setValueRaw(entry.data.value);
    }



};