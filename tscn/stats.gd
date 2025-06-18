extends CanvasLayer
var arr_health = []


func _process(_delta: float) -> void:
	var health = get_parent().health
	var max_health = get_parent().max_health / 4
	var cur_health = 0
	for i in arr_health:
		cur_health += int(i.tooltip_text)
	if cur_health != health:
		for i in arr_health:
			i.queue_free()
		arr_health = []
		for i in range(health / 4):
			var spri = TextureRect.new()
			spri.texture = load("res://assets/ui/4.png")
			spri.tooltip_text = "4"
			get_node("Health").add_child(spri)
			arr_health.append(spri)
		if health > len(arr_health) * 4:
			var spri = TextureRect.new()
			spri.texture = load('res://assets/ui/{n}.png'.format({"n": (health - len(arr_health) * 4)}))
			spri.tooltip_text = str(health - len(arr_health) * 4)
			get_node("Health").add_child(spri)
			arr_health.append(spri)
		if len(arr_health) != max_health:
			for i in range(max_health - len(arr_health)):
				var spri = TextureRect.new()
				spri.texture = load("res://assets/ui/0.png")
				spri.tooltip_text = "0"
				get_node("Health").add_child(spri)
				arr_health.append(spri)
