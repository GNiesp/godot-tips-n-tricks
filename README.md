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

### Possible languages
Godot offers 2 fully supported languages to create games. Those are:
- GDscript - Python like language with easy to learn curve & multiple possibilities, but with some scalability problems in larger codebases
- .NET/C# - Microsoft backed language used as an alternative to GDScript. Also used in Unity so it's often choosed by people migrating to Godot from that engine.

There are benefits & downsides to both of these languages and there isn't one best decision when it comes to choosing between them.
GDscript used in Godot offers what I'd call "hot reload" meaning that the changes done in code while game is running will have impact in a game. That's useful for example when we prototype some features & want to check quickly multiple various for gravity, speed, etc.
C# on the other hand doesn't have hot reload, but it has something that GDScript lacks. Years of constant improvement & really good scalability in larger games. It has strong object oriented features like interfaces, virtual methods, class extensions & others that GDScript (at the moment) lacks.

There's also one crucial difference between those languages. Visibility of funcs & variables. GDScript is really relaxed when it comes to differentiating between private/public funcs & variables which might lead to some really poor quality code as shown below:
```
# Private built-in _ready func from another class is used inside other class.
# Not only that it might lead to unexpected behavior like twice initialization of some variables
# But it also might create some really tricky to find bugs
other_class._ready()
```

In case of .NET we simply can't call other classes private methods & variables which practically make that issue not existant.

### A word about signals
In general connecting nodes that are in separate branches of scene tree & are far away should be made using signals with the use of **SignalBus** or with the use of specialized _\_data_ resources.

There are multiple ways to connect to signal in Godot, but the most type safe way is to use following syntax:
```
signal_name.connect(callback_func) # Does the same as connect("signal_name", callback_func), but in type safe way
```

### Rare _process rule
Each time you want to use _process func you need to answer 2 questions:
1. Do I need delta since last frame? Yes -> Use _process, No -> Go to step 2
2. Do I need to update state each frame? Yes -> Use _process, No -> Just rely on signals

Although using signals usually will result in additional 2-3 lines of code it can very effectively separate concerns.
Example using _process:
```
extends Node

@onready var hp_label: Label = %HPLabel
@onready var money_label: Label = %MoneyLabel

func _process(_delta: float) -> void:
    hp_label.text = str(ProcessSourceOfTruth.player_hp)
    money_label.text = str(ProcessSourceOfTruth.player_money)
```

Example using signals:
```
extends Node

@onready var hp_label: Label = %HPLabel
@onready var money_label: Label = %MoneyLabel

func _ready() -> void:
    ProcessSourceOfTruth.player_hp_changed.connect(_on_player_hp_changed)
    ProcessSourceOfTruth.player_money_changed.connect(_on_player_money_changed)

func _on_player_hp_changed(hp: int):
    hp_label.text = str(hp)

func _on_player_money_changed(money: int):
    money_label.text = str(money)
```

Although using signals added additional lines it's still preferable because:
- It's more efficient to use set value only when it's changed rather than 60 times per second even if no change happened.
- It's easier to track specific callbacks - we clearly se what happens on certain signal emit & we can easily modify that single func rather than modifying whole _process func.


### Stateful Types
For int, float, string, bool there are a wrapper classes that make them stateful - IntSF, FloatSF, StringSF, BoolSF. Nodes can subscribe to their _changed(data)_ signal. It should be used everywhere where reactivity is needed eg. UIs.

**IMPORTANT** - those stateful types are on average about 16x times slower in instantion than simple types & although they are still very cheap in situations where reactivity isn't needed & over few thousand new instances are needed (like long Arrays) it will be faster to use simple types. 


### Branching
It should follow GitFlow Workflow rules.
![GitFlow Workflow Graph](README_assets/gitflow.webp)

There should be 2 static branches that is:
- **main** - official builds are created from here. All the code that lands on this branch should be well tested & production ready.
- **develop** - main development branch. That's the only (aside from hotfixes) branch that can be merged into main.

For any feature development there should be a branch created basing on **develop** branch.
For production updates there should be **release** branch created that has to be tested & approved before actual release.



### Factory constructors / Dynamic scene instantiation
Each scene that needs to be dynamically added should offer _static func new\_instance()_ in it's script that's return type should be it's class_name.
Example:
```
class_name Main extends Node

static func new_instance() -> Main:
    const SCENE := preload("./scene.tscn") # It's useful to create const here instead of whole script to enable inherited scenes to inject their own scenes in factory constructor.
    var main: Main = SCENE.instantiate()
    # Any value assignments go here
    return main
```
That way we get strong typing everywhere we need instantiate some scene.
```
# Godot now can deduce the type of instantiated scene -> Normally it'd fall back to Node type
# Additionally our code is much more declarative and is more readable
var our_instance := Main.new_instance()  
```

### External Data Sources
In general our in game elements should be as brainless as they can be. Sometimes we have some data stored for example in GameManager & that data has to be used in a few different places in the same screen.
Good example would be our items equipment - we want to show each individual item slot, total number of slots used, total weight of items, etc. In that case we will have at least few different nodes.
It's easy to just get the data from GameManager in each element's individual script, but it has at least a few downsides.
First is coupling of many elements with some data. On that data refactor or our node's refactor we'd have to iterate over many different scripts just to change their data source.
Secondly there is space for desync between different nodes of the scene as each node gets value from GameManager on it's own & possibly in the different time.

Solution to this is top-to-bottom data flow in which we'd get all neccessary data in the scene's root node & that data would be used in it's children. In case of more complex UI it can be difficult to pass the data down from node to node at there might be a lot of scenes included in each other and not all of them using this data. Solution to that problem is described in _Data-driven design_ paragraph.

### Data-driven design
Nodes shouldn't (in most cases) rely on each other when it comes to data. Instead they should subscribe to values of a separate Resource which works as [SSOT](https://www.getguru.com/reference/single-source-of-truth). That way nodes are independent of each other and can be easily detached or attached to node tree. 

Example:
```
# minigame_data.gd

var score: float:
    set(value):
        score = value
        score_set.emit(score)
signal score_set(value: float)
var action: Action:
    set(value):
        action = value
        action_set.emit(action)
signal action_set(value: Action)
var ingredient: Ingredient:
    set(value):
        ingredient = value
        ingredient_set.emit(ingredient)
signal ingredient_set(value: Ingredient)
```

And then it can be easily used in any Node no matter where it resides in the scene tree after Resource is created:
```
@export var minigame_end_screen_data: MinigameEndScreenData
```

### Folders
Each scene + script should be moved into separate folder.
Purpose of preexisting folders:
- **assets** - stores all images, fonts, shaders, models, music, sfxes & all other posible assets that are not directly included in node tree & aren't custom Resources
- **const_data** - stores custom Resources that are supposed to be set once before game start & never further changed.
- **dev** - stores artifacts of dev mode like screenshots, recordings, etc.
- **src** - stores managers, utils, scenes & scenes' data. Folders inside _src_ should follow fetaure-based approach.
- **tests** - stores tests for scenes & scripts.
 
### Saves
Saves should be created using custom Resource class containing all the info that needs to be saved.

There is one crucial downside of using Resources for saves - Resources can be executed & potentially someone could inject malware into those files so using someone's save is **not** safe!

### UI Data
Data for complex UI elements like menues, maps, tables, etc. should be stored in a specialized Resource with _\_data_ suffix. There should be only one instance of such data component stored in filesystem and that file should be used as a single source of truth for whole node tree that needs that data.

Resources get autodestructed when no node reads from them so each time new interface is created fresh state is produced.

### Formatter
Formatter should be used while developing any Godot project in order to assert good code standard.
