# SocialMedia.gd - Social media campaign management
class_name SocialMedia
extends Control

@onready var navigation_bar: NavigationBar = $VBoxContainer/NavigationBar
@onready var platform_options: OptionButton = $VBoxContainer/SocialContent/PostComposer/PlatformSelector/PlatformOptions
@onready var message_input: TextEdit = $VBoxContainer/SocialContent/PostComposer/PostContent/MessageInput
@onready var character_count: Label = $VBoxContainer/SocialContent/PostComposer/PostContent/CharacterCount
@onready var your_posts_list: VBoxContainer = $"VBoxContainer/SocialContent/FeedContainer/FeedTabs/Your Posts/YourPostsList"
@onready var trending_list: VBoxContainer = $VBoxContainer/SocialContent/FeedContainer/FeedTabs/Trending/TrendingList
@onready var mentions_list: VBoxContainer = $VBoxContainer/SocialContent/FeedContainer/FeedTabs/Mentions/MentionsList

# Analytics
@onready var followers_label: Label = $VBoxContainer/SocialContent/Analytics/StatsContainer/StatsContent/EngagementStats/Followers
@onready var likes_label: Label = $VBoxContainer/SocialContent/Analytics/StatsContainer/StatsContent/EngagementStats/Likes
@onready var shares_label: Label = $VBoxContainer/SocialContent/Analytics/StatsContainer/StatsContent/EngagementStats/Shares
@onready var weekly_reach_label: Label = $VBoxContainer/SocialContent/Analytics/StatsContainer/StatsContent/ReachStats/WeeklyReach
@onready var political_impact_label: Label = $VBoxContainer/SocialContent/Analytics/StatsContainer/StatsContent/ReachStats/PoliticalImpact

# Control buttons
@onready var policy_button: Button = $VBoxContainer/SocialContent/PostComposer/PostOptions/PostTypeButtons/PolicyButton
@onready var opinion_button: Button = $VBoxContainer/SocialContent/PostComposer/PostOptions/PostTypeButtons/OpinionButton
@onready var response_button: Button = $VBoxContainer/SocialContent/PostComposer/PostOptions/PostTypeButtons/ResponseButton
@onready var post_button: Button = $VBoxContainer/SocialContent/PostComposer/PostControls/PostButton

# Signals
signal post_published(platform: String, content: String, type: String)
signal navigation_requested(screen: String)

# Social media data
var user_posts: Array = []
var trending_topics: Array = []
var mentions: Array = []
var selected_post_type: String = ""
var character_limits = {"twitter": 280, "facebook": 63206, "linkedin": 3000}
var social_analytics: Dictionary = {}

func _ready():
	setup_accessibility()
	setup_navigation()
	load_social_data()
	update_analytics()

func setup_accessibility():
	"""Configure accessibility for social media interface"""
	platform_options.focus_mode = Control.FOCUS_ALL
	message_input.focus_mode = Control.FOCUS_ALL
	policy_button.focus_mode = Control.FOCUS_ALL
	opinion_button.focus_mode = Control.FOCUS_ALL
	response_button.focus_mode = Control.FOCUS_ALL
	post_button.focus_mode = Control.FOCUS_ALL

func setup_navigation():
	"""Connect navigation signals"""
	if navigation_bar:
		navigation_bar.navigation_requested.connect(_on_navigation_requested)
		navigation_bar.set_active_screen("social")

func load_social_data():
	"""Load social media content and data"""
	# This will be connected to SimulationAPI in Phase 3.7
	create_sample_social_data()
	populate_social_feeds()

func create_sample_social_data():
	"""Create sample social media posts and data"""
	user_posts = [
		{
			"id": "post_001",
			"platform": "twitter",
			"content": "Proud to announce our new healthcare initiative. Every Dutch citizen deserves accessible care! 🏥 #HealthcareForAll",
			"timestamp": "2 hours ago",
			"likes": 245,
			"shares": 67,
			"comments": 34,
			"type": "policy"
		},
		{
			"id": "post_002",
			"platform": "facebook",
			"content": "Just finished an inspiring meeting with healthcare workers in Amsterdam. Their dedication is truly remarkable.",
			"timestamp": "1 day ago",
			"likes": 189,
			"shares": 23,
			"comments": 56,
			"type": "opinion"
		}
	]

	trending_topics = [
		{
			"topic": "#ClimateSummit2024",
			"posts": 15234,
			"engagement": "High",
			"political_relevance": 0.9
		},
		{
			"topic": "#DutchElections",
			"posts": 8947,
			"engagement": "Very High",
			"political_relevance": 1.0
		},
		{
			"topic": "#HealthcareReform",
			"posts": 5632,
			"engagement": "Medium",
			"political_relevance": 0.8
		}
	]

	mentions = [
		{
			"id": "mention_001",
			"author": "@VoterAmsterdam",
			"content": "What's your stance on the new education budget proposals?",
			"timestamp": "30 min ago",
			"sentiment": "neutral"
		},
		{
			"id": "mention_002",
			"author": "@HealthWorkerNL",
			"content": "Thank you for supporting our healthcare workers! This means a lot to us.",
			"timestamp": "2 hours ago",
			"sentiment": "positive"
		}
	]

	social_analytics = {
		"followers": {"twitter": 12450, "facebook": 8934, "linkedin": 5678},
		"weekly_reach": 45230,
		"engagement_rate": 0.078,
		"political_impact": 0.156,
		"avg_likes": 167,
		"avg_shares": 34
	}

func populate_social_feeds():
	"""Populate all social media feed sections"""
	populate_user_posts()
	populate_trending_topics()
	populate_mentions()

func populate_user_posts():
	"""Fill user's posts list"""
	clear_container(your_posts_list)

	for post in user_posts:
		create_post_card(post, your_posts_list)

func populate_trending_topics():
	"""Fill trending topics list"""
	clear_container(trending_list)

	for topic in trending_topics:
		create_trending_item(topic, trending_list)

func populate_mentions():
	"""Fill mentions list"""
	clear_container(mentions_list)

	for mention in mentions:
		create_mention_card(mention, mentions_list)

func create_post_card(post: Dictionary, parent: VBoxContainer):
	"""Create a social media post card"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)

	var card_content = VBoxContainer.new()
	card.add_child(card_content)

	# Post header
	var header = HBoxContainer.new()
	card_content.add_child(header)

	var platform_label = Label.new()
	platform_label.text = post.platform.capitalize()
	platform_label.theme_type_variation = "HeaderSmall"
	header.add_child(platform_label)

	var timestamp_label = Label.new()
	timestamp_label.text = post.timestamp
	timestamp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timestamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(timestamp_label)

	# Post content
	var content_label = Label.new()
	content_label.text = post.content
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_content.add_child(content_label)

	# Engagement stats
	var stats = HBoxContainer.new()
	card_content.add_child(stats)

	var likes_stat = Label.new()
	likes_stat.text = "❤️ %d" % post.likes
	stats.add_child(likes_stat)

	var shares_stat = Label.new()
	shares_stat.text = "🔄 %d" % post.shares
	stats.add_child(shares_stat)

	var comments_stat = Label.new()
	comments_stat.text = "💬 %d" % post.comments
	stats.add_child(comments_stat)

	parent.add_child(card)

func create_trending_item(topic: Dictionary, parent: VBoxContainer):
	"""Create a trending topic item"""
	var item = HBoxContainer.new()

	var topic_label = Label.new()
	topic_label.text = topic.topic
	topic_label.theme_type_variation = "HeaderSmall"
	topic_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(topic_label)

	var posts_label = Label.new()
	posts_label.text = "%d posts" % topic.posts
	posts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	item.add_child(posts_label)

	parent.add_child(item)

func create_mention_card(mention: Dictionary, parent: VBoxContainer):
	"""Create a mention notification card"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)

	var card_content = VBoxContainer.new()
	card.add_child(card_content)

	# Mention header
	var header = HBoxContainer.new()
	card_content.add_child(header)

	var author_label = Label.new()
	author_label.text = mention.author
	author_label.theme_type_variation = "HeaderSmall"
	header.add_child(author_label)

	var time_label = Label.new()
	time_label.text = mention.timestamp
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(time_label)

	# Mention content
	var content_label = Label.new()
	content_label.text = mention.content
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_content.add_child(content_label)

	# Color code by sentiment
	match mention.sentiment:
		"positive":
			card.modulate = Color(0.9, 1.0, 0.9)
		"negative":
			card.modulate = Color(1.0, 0.9, 0.9)
		"neutral":
			card.modulate = Color.WHITE

	parent.add_child(card)

func update_analytics():
	"""Update social media analytics display"""
	var platform = get_selected_platform_key()
	var follower_count = social_analytics.followers.get(platform, 0)

	followers_label.text = "Followers: %s" % format_number(follower_count)
	likes_label.text = "Avg Likes: %d" % social_analytics.avg_likes
	shares_label.text = "Avg Shares: %d" % social_analytics.avg_shares
	weekly_reach_label.text = "Weekly Reach: %s" % format_number(social_analytics.weekly_reach)
	political_impact_label.text = "Political Impact: %.1f%%" % (social_analytics.political_impact * 100)

func get_selected_platform_key() -> String:
	"""Get the currently selected platform key"""
	match platform_options.selected:
		0: return "twitter"
		1: return "facebook"
		2: return "linkedin"
		_: return "twitter"

func format_number(num: int) -> String:
	"""Format large numbers with suffixes"""
	if num >= 1000000:
		return "%.1fM" % (num / 1000000.0)
	elif num >= 1000:
		return "%.1fK" % (num / 1000.0)
	else:
		return str(num)

func update_character_count():
	"""Update the character count display"""
	var platform_key = get_selected_platform_key()
	var limit = character_limits.get(platform_key, 280)
	var current_length = message_input.text.length()

	character_count.text = "%d/%d characters" % [current_length, limit]

	# Color code based on limit
	if current_length > limit:
		character_count.modulate = Color.RED
		post_button.disabled = true
	elif current_length > limit * 0.9:
		character_count.modulate = Color.YELLOW
		post_button.disabled = false
	else:
		character_count.modulate = Color.WHITE
		post_button.disabled = false

func clear_container(container: VBoxContainer):
	"""Clear all children from a container"""
	for child in container.get_children():
		child.queue_free()

func _on_message_input_text_changed():
	"""Handle message input text changes"""
	update_character_count()

func _on_policy_button_pressed():
	"""Handle policy post type selection"""
	selected_post_type = "policy"
	highlight_selected_post_type()

func _on_opinion_button_pressed():
	"""Handle opinion post type selection"""
	selected_post_type = "opinion"
	highlight_selected_post_type()

func _on_response_button_pressed():
	"""Handle response post type selection"""
	selected_post_type = "response"
	highlight_selected_post_type()

func highlight_selected_post_type():
	"""Highlight the selected post type button"""
	# Reset all buttons
	policy_button.modulate = Color.WHITE
	opinion_button.modulate = Color.WHITE
	response_button.modulate = Color.WHITE

	# Highlight selected
	match selected_post_type:
		"policy":
			policy_button.modulate = Color(0.8, 1.0, 0.8)
		"opinion":
			opinion_button.modulate = Color(0.8, 1.0, 0.8)
		"response":
			response_button.modulate = Color(0.8, 1.0, 0.8)

func _on_save_draft_button_pressed():
	"""Handle saving post as draft"""
	if message_input.text.strip_edges().is_empty():
		return

	print("Saved draft: ", message_input.text.left(50), "...")

func _on_post_button_pressed():
	"""Handle publishing social media post"""
	var content = message_input.text.strip_edges()
	if content.is_empty():
		return

	var platform_key = get_selected_platform_key()
	var limit = character_limits.get(platform_key, 280)

	if content.length() > limit:
		print("Post too long for platform")
		return

	post_published.emit(platform_key, content, selected_post_type)

	# Add to user posts
	var new_post = {
		"id": "post_%d" % (user_posts.size() + 1),
		"platform": platform_key,
		"content": content,
		"timestamp": "Now",
		"likes": 0,
		"shares": 0,
		"comments": 0,
		"type": selected_post_type
	}
	user_posts.insert(0, new_post)

	# Clear input
	message_input.text = ""
	selected_post_type = ""
	highlight_selected_post_type()
	update_character_count()
	populate_user_posts()

	print("Posted to %s: %s" % [platform_key, content.left(50)])

func _on_navigation_requested(screen: String):
	"""Handle navigation to other screens"""
	navigation_requested.emit(screen)