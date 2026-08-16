# GODOT Tips'n'Tricks
 
## Reasoning
Godot engine has multiple great tutorials & guidelines that provide ways to manage small, medium-sized & large projects, it lacks one unified base with standardized codebase rules that can make managing any project easier.

## Contents
The repository is created to:
- Enable faster & more standardized code development among multiple projects
- Share base godot's project template that can be used as a good start for any new project
- Interactively show reasons behind certain convention for dirs, scenes & scripts naming
- Provide ways for lasting & easy to refactor code that is:
  - **loosly coupled** - refactoring one module won't affect others too much
  - **compile time safe** - usage of typing & assetions make bugs occur on game's launch
  - **modular** - each module affects only it's state
 
### Saves
Saves should be created using custom Resource class containing all the info that needs to be saved.

### UI Data
Data for complex UI elements like menues, maps, tables, etc. should be stored in a specialized Resource with _\_data_ suffix. There should be only one instance of such data component stored in filesystem and that file should be used as a single source of truth for whole node tree that needs that data.

Resources get autodestructed when no node reads from them so each time new interface is created fresh state is produced.

### Simple Types Stateful Wrapper
For each simple type like int, string, etc. there is a wrapper class that make them stateful - other nodes can subscribe to it's _changed(data)_ signal. It should be used everywhere where reactivity is needed eg. UIs.

### Formatter
Formatter should be used while developing any Godot project in order to assert good code standard.
