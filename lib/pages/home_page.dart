  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: Icon(
                  icon,
                  color: const Color(0xff159cf1),
                  size: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(