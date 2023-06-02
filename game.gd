extends Node2D

var Ball = preload("res://ball.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	$Ball.linear_velocity = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()*200


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var ball = get_node("Ball")
	if Input.is_action_pressed("ui_left"):
		$PaddlePivot.rotation -= delta * 2*PI;
	if Input.is_action_pressed("ui_right"):
		$PaddlePivot.rotation += delta * 2*PI;
		
	if ai_active:
		$PaddlePivot.rotation += delta * 2*PI * ai_action;
	
	get_node("Ball").linear_velocity = $Ball.linear_velocity.normalized()*200
	
	if ball.position.x < 0 or \
	ball.position.y < 0 or \
	ball.position.x > 800 or \
	ball.position.y > 800:
		remove_child(ball)
		ball.queue_free()
		call_deferred("add_new_ball")
	
func add_new_ball():
	var ball = Ball.instantiate()
	add_child(ball)
	ball.position = Vector2(400, 400)
	ball.linear_velocity = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()*200
	ball.name = "Ball"
	

func _process(delta):
	if ai_active:
		var image = get_viewport().get_texture().get_image()
		image.resize(100, 100)
		var image_buffer = image.save_png_to_buffer()
		sock.put_u32(0)
		sock.put_32(image_buffer.size())
		sock.put_data(image_buffer)
		var rec_pid = sock.get_32()
		if rec_pid == 1:
			ai_action = sock.get_32()
	

func _on_check_button_toggled(button_pressed):
	if button_pressed:
		connect_ai()
	else:
		disconnect_ai()

var sock: StreamPeerTCP = null
var ai_active = false
var ai_action = 0
func connect_ai():
	sock = StreamPeerTCP.new()
	var connect = sock.connect_to_host("127.0.0.1", 3000)
	sock.set_no_delay(true)
	sock.poll()
	ai_active = true
	
func disconnect_ai():
	if sock:
		sock.disconnect_from_host()
	ai_active = false
