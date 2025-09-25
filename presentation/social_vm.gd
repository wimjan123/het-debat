# SocialViewModel.gd - View model for social media management
class_name SocialViewModel
extends BaseViewModel

# Signals
signal post_published(post: Dictionary)
signal feed_updated(posts: Array)
signal analytics_updated(metrics: Dictionary)
signal mentions_updated(mentions: Array)

# Dependencies
var simulation_api: SimulationAPI

# State
var user_posts: Array = []
var trending_topics: Array = []
var mentions: Array = []
var analytics_data: Dictionary = {}
var draft_posts: Array = []

func initialize_with_api(sim_api: SimulationAPI):
	"""Initialize view model with API dependency"""
	simulation_api = sim_api

	if simulation_api:
		simulation_api.social_mention_received.connect(_on_mention_received)
		simulation_api.trending_topics_updated.connect(_on_trending_updated)

	await load_social_data()

func load_social_data():
	"""Load all social media data"""
	if not simulation_api:
		return

	var social_data = await simulation_api.get_social_media_data()
	user_posts = social_data.get("posts", [])
	trending_topics = social_data.get("trending", [])
	mentions = social_data.get("mentions", [])

	analytics_data = await simulation_api.get_social_analytics()

	feed_updated.emit(user_posts)
	analytics_updated.emit(analytics_data)
	mentions_updated.emit(mentions)

func create_post(platform: String, content: String, post_type: String = "") -> Dictionary:
	"""Create and publish a social media post"""
	if not simulation_api:
		return {"error": "API not available"}

	# Validate content length for platform
	var max_length = _get_platform_max_length(platform)
	if content.length() > max_length:
		return {"error": "Content too long for platform"}

	var post_data = {
		"platform": platform,
		"content": content,
		"type": post_type,
		"timestamp": Time.get_datetime_string_from_system()
	}

	var result = await simulation_api.publish_social_post(post_data)

	if result.get("success", false):
		var published_post = result.get("post", {})
		user_posts.insert(0, published_post)
		feed_updated.emit(user_posts)
		post_published.emit(published_post)

		# Show success notification
		show_notification("post_published", UIDataModels.NotificationType.SUCCESS, {
			"platform": platform,
			"content_preview": content.left(50)
		})

	return result

func save_draft(platform: String, content: String, post_type: String = "") -> String:
	"""Save a post as draft"""
	var draft = {
		"id": generate_unique_id(),
		"platform": platform,
		"content": content,
		"type": post_type,
		"created_at": Time.get_datetime_string_from_system()
	}

	draft_posts.append(draft)
	return draft.id

func publish_draft(draft_id: String) -> Dictionary:
	"""Publish a saved draft"""
	var draft = _find_draft_by_id(draft_id)
	if not draft:
		return {"error": "Draft not found"}

	var result = await create_post(draft.platform, draft.content, draft.type)

	if result.get("success", false):
		draft_posts.erase(draft)

	return result

func delete_post(post_id: String) -> bool:
	"""Delete a published post"""
	if not simulation_api:
		return false

	var result = await simulation_api.delete_social_post(post_id)

	if result.get("success", false):
		# Remove from local posts
		var post = _find_post_by_id(post_id)
		if post:
			user_posts.erase(post)
			feed_updated.emit(user_posts)

	return result.get("success", false)

func get_post_analytics(post_id: String) -> Dictionary:
	"""Get detailed analytics for a specific post"""
	if not simulation_api:
		return {}

	return await simulation_api.get_post_analytics(post_id)

func respond_to_mention(mention_id: String, response: String) -> Dictionary:
	"""Respond to a social media mention"""
	if not simulation_api:
		return {"error": "API not available"}

	var response_data = {
		"mention_id": mention_id,
		"response": response,
		"timestamp": Time.get_datetime_string_from_system()
	}

	var result = await simulation_api.respond_to_mention(response_data)

	if result.get("success", false):
		# Mark mention as responded
		var mention = _find_mention_by_id(mention_id)
		if mention:
			mention["responded"] = true
			mention["response"] = response
			mentions_updated.emit(mentions)

	return result

func get_trending_analysis() -> Dictionary:
	"""Get analysis of trending topics"""
	return {
		"total_trending": trending_topics.size(),
		"political_relevance": _calculate_political_relevance(),
		"opportunity_score": _calculate_engagement_opportunities(),
		"recommended_topics": _get_recommended_topics()
	}

func get_social_media_strategy() -> Dictionary:
	"""Get AI-generated social media strategy suggestions"""
	if not simulation_api:
		return {}

	var strategy_input = {
		"current_metrics": analytics_data,
		"recent_posts": user_posts.slice(0, 10),
		"trending_topics": trending_topics,
		"mentions_sentiment": _analyze_mentions_sentiment()
	}

	return await simulation_api.generate_social_strategy(strategy_input)

func schedule_post(platform: String, content: String, scheduled_time: String) -> Dictionary:
	"""Schedule a post for future publication"""
	if not simulation_api:
		return {"error": "API not available"}

	var schedule_data = {
		"platform": platform,
		"content": content,
		"scheduled_time": scheduled_time
	}

	return await simulation_api.schedule_social_post(schedule_data)

func get_engagement_metrics() -> Dictionary:
	"""Get current engagement metrics"""
	return {
		"total_followers": analytics_data.get("followers", 0),
		"avg_engagement_rate": analytics_data.get("engagement_rate", 0.0),
		"posts_this_week": _count_recent_posts(7),
		"mentions_this_week": _count_recent_mentions(7),
		"reach_this_week": analytics_data.get("weekly_reach", 0),
		"sentiment_score": _calculate_overall_sentiment()
	}

func _get_platform_max_length(platform: String) -> int:
	"""Get maximum character limit for platform"""
	match platform.to_lower():
		"twitter", "x":
			return 280
		"facebook":
			return 63206
		"linkedin":
			return 3000
		"instagram":
			return 2200
		_:
			return 280  # Default to Twitter limit

func _find_post_by_id(post_id: String) -> Dictionary:
	"""Find post by ID in user posts"""
	for post in user_posts:
		if post.get("id", "") == post_id:
			return post
	return {}

func _find_draft_by_id(draft_id: String) -> Dictionary:
	"""Find draft by ID"""
	for draft in draft_posts:
		if draft.get("id", "") == draft_id:
			return draft
	return {}

func _find_mention_by_id(mention_id: String) -> Dictionary:
	"""Find mention by ID"""
	for mention in mentions:
		if mention.get("id", "") == mention_id:
			return mention
	return {}

func _calculate_political_relevance() -> float:
	"""Calculate political relevance of trending topics"""
	if trending_topics.is_empty():
		return 0.0

	var political_count = 0
	for topic in trending_topics:
		if topic.get("political_relevance", 0.0) > 0.5:
			political_count += 1

	return float(political_count) / float(trending_topics.size())

func _calculate_engagement_opportunities() -> float:
	"""Calculate score for engagement opportunities"""
	var opportunity_score = 0.0

	# High engagement trending topics
	for topic in trending_topics:
		var engagement = topic.get("engagement", "low")
		var relevance = topic.get("political_relevance", 0.0)

		if engagement == "high" and relevance > 0.7:
			opportunity_score += 0.3
		elif engagement == "medium" and relevance > 0.5:
			opportunity_score += 0.2

	return min(opportunity_score, 1.0)

func _get_recommended_topics() -> Array:
	"""Get recommended topics for posting"""
	var recommendations = []

	for topic in trending_topics:
		var relevance = topic.get("political_relevance", 0.0)
		var engagement = topic.get("engagement", "low")

		if relevance > 0.6 and engagement in ["high", "medium"]:
			recommendations.append(topic)

	# Sort by relevance score
	recommendations.sort_custom(func(a, b): return a.get("political_relevance", 0.0) > b.get("political_relevance", 0.0))

	return recommendations.slice(0, 5)  # Top 5 recommendations

func _analyze_mentions_sentiment() -> Dictionary:
	"""Analyze sentiment of recent mentions"""
	var sentiment_counts = {"positive": 0, "neutral": 0, "negative": 0}

	for mention in mentions:
		var sentiment = mention.get("sentiment", "neutral")
		sentiment_counts[sentiment] = sentiment_counts.get(sentiment, 0) + 1

	return sentiment_counts

func _count_recent_posts(days: int) -> int:
	"""Count posts from last N days"""
	var count = 0
	var cutoff_time = Time.get_datetime_string_from_system()  # Simplified

	for post in user_posts:
		# Simplified time comparison
		count += 1  # Would implement proper date comparison

	return count

func _count_recent_mentions(days: int) -> int:
	"""Count mentions from last N days"""
	var count = 0

	for mention in mentions:
		# Simplified time comparison
		count += 1  # Would implement proper date comparison

	return count

func _calculate_overall_sentiment() -> float:
	"""Calculate overall sentiment score from mentions"""
	var sentiment_analysis = _analyze_mentions_sentiment()
	var total = sentiment_analysis.positive + sentiment_analysis.neutral + sentiment_analysis.negative

	if total == 0:
		return 0.5  # Neutral

	# Weighted sentiment score
	var score = (sentiment_analysis.positive * 1.0 + sentiment_analysis.neutral * 0.5) / total
	return score

func generate_unique_id() -> String:
	"""Generate unique ID for drafts"""
	return "draft_" + str(Time.get_ticks_msec())

# Signal handlers
func _on_mention_received(mention_data: Dictionary):
	"""Handle new social media mention"""
	mentions.insert(0, mention_data)
	mentions_updated.emit(mentions)

	# Show notification for important mentions
	var sentiment = mention_data.get("sentiment", "neutral")
	if sentiment == "negative":
		show_notification("negative_mention", UIDataModels.NotificationType.WARNING, {
			"author": mention_data.get("author", "Unknown")
		})

func _on_trending_updated(trending_data: Array):
	"""Handle trending topics update"""
	trending_topics = trending_data