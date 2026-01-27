/**
 * @description Page state enumeration for UI state management
 * @author STARLUX Development Team
 * @date 2024
 */
public class PageState {
    
    // State constants
    public static final String SEARCH = 'SEARCH';
    public static final String LOADING = 'LOADING';
    public static final String RESULTS = 'RESULTS';
    public static final String EDITING = 'EDITING';
    public static final String SAVING = 'SAVING';
    public static final String ERROR = 'ERROR';
    
    public String currentState { get; private set; }
    public DateTime stateChangeTime { get; private set; }
    public String previousState { get; private set; }
    
    /**
     * @description Constructor with initial state
     * @param initialState Initial page state
     */
    public PageState(String initialState) {
        this.currentState = initialState != null ? initialState : SEARCH;
        this.stateChangeTime = DateTime.now();
        this.previousState = null;
    }
    
    /**
     * @description Default constructor
     */
    public PageState() {
        this(SEARCH);
    }
    
    /**
     * @description Change to new state
     * @param newState New state to transition to
     */
    public void changeState(String newState) {
        if (newState != null && newState != this.currentState) {
            this.previousState = this.currentState;
            this.currentState = newState;
            this.stateChangeTime = DateTime.now();
        }
    }
    
    /**
     * @description Check if currently in specific state
     * @param state State to check
     * @return True if in specified state
     */
    public Boolean isInState(String state) {
        return this.currentState == state;
    }
    
    /**
     * @description Check if in search state
     * @return True if in search state
     */
    public Boolean isSearching() {
        return isInState(SEARCH);
    }
    
    /**
     * @description Check if in loading state
     * @return True if loading
     */
    public Boolean isLoading() {
        return isInState(LOADING);
    }
    
    /**
     * @description Check if showing results
     * @return True if showing results
     */
    public Boolean isShowingResults() {
        return isInState(RESULTS);
    }
    
    /**
     * @description Check if in editing mode
     * @return True if editing
     */
    public Boolean isEditing() {
        return isInState(EDITING);
    }
    
    /**
     * @description Check if saving
     * @return True if saving
     */
    public Boolean isSaving() {
        return isInState(SAVING);
    }
    
    /**
     * @description Check if in error state
     * @return True if in error state
     */
    public Boolean hasError() {
        return isInState(ERROR);
    }
    
    /**
     * @description Get valid state transitions from current state
     * @return List of valid next states
     */
    public List<String> getValidTransitions() {
        List<String> validStates = new List<String>();
        
        switch on currentState {
            when 'SEARCH' {
                validStates.addAll(new List<String>{LOADING, ERROR});
            }
            when 'LOADING' {
                validStates.addAll(new List<String>{RESULTS, ERROR, SEARCH});
            }
            when 'RESULTS' {
                validStates.addAll(new List<String>{EDITING, SEARCH, ERROR});
            }
            when 'EDITING' {
                validStates.addAll(new List<String>{SAVING, RESULTS, ERROR});
            }
            when 'SAVING' {
                validStates.addAll(new List<String>{RESULTS, ERROR});
            }
            when 'ERROR' {
                validStates.addAll(new List<String>{SEARCH, RESULTS});
            }
        }
        
        return validStates;
    }
}