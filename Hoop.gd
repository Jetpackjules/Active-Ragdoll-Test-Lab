extends StaticBody2D


onready var timer = get_node("Timer")
onready var score = get_node("../Score")
var body_inside

var left_score = 0
var right_score = 0


func _on_Hoop_Goal_body_entered(body):
	if body.is_in_group("score-able"):
		body_inside = body
		timer.start() 

func _on_Hoop_Goal_body_exited(body):
	if body.is_in_group("score-able"):
		timer.stop()
		timer.wait_time = 2
	
func _on_Timer_timeout():
	body_inside.emit_signal("done")
	body_inside.queue_free()
	var neem = name
	if "right" in name:
		left_score += 1
	else:
		right_score += 1
	
	var left_score_text
	var right_score_text
	if left_score == 0:
		left_score_text = "0 "
	else:
		left_score_text = str(left_score)
	if right_score == 0:
		right_score_text = " 0"
	else:
		right_score_text = str(left_score)
	
	score.text =  left_score_text + " -" + right_score_text

